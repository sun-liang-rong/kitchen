import { BadRequestException, Injectable } from '@nestjs/common';
import {
  CoupleStatus,
  FeedType,
  PointReason,
  PointTransactionType,
  Prisma,
  SpiritLogType,
  SpiritMood,
  SpiritStage,
  SpiritStyle,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

type Tx = Prisma.TransactionClient;

const SHANGHAI_OFFSET_MS = 8 * 60 * 60 * 1000;

const POINT_REWARDS: Record<
  Exclude<PointReason, 'FEED_SPIRIT'>,
  { points: number; dailyLimit?: number }
> = {
  CHECKIN: { points: 10 },
  CREATE_WISH: { points: 5, dailyLimit: 3 },
  RESPOND_WISH: { points: 8, dailyLimit: 3 },
  CONFIRM_RESPONSE: { points: 10, dailyLimit: 3 },
  FULFILL_WISH: { points: 20 },
  ADD_DISH: { points: 5, dailyLimit: 5 },
};

const FEED_RULES: Record<FeedType, { points: number; exp: number; label: string }> = {
  NORMAL: { points: 10, exp: 10, label: '普通喂养' },
  DELICATE: { points: 30, exp: 35, label: '精致喂养' },
  FEAST: { points: 80, exp: 100, label: '大餐喂养' },
};

@Injectable()
export class RewardsService {
  constructor(private readonly prisma: PrismaService) {}

  async getSpirit(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    const [spirit, points, checkin] = await this.prisma.$transaction(async (tx) => {
      const spirit = await this.ensureSpirit(tx, couple.id);
      const points = await this.ensurePointAccount(tx, couple.id);
      const checkin = await this.getCheckinStatusInTx(tx, userId, couple.id);
      return [spirit, points, checkin] as const;
    });
    return {
      spirit: this.spiritPayload(this.withDisplayMood(spirit)),
      points,
      checkin,
    };
  }

  async renameSpirit(userId: string, name: string) {
    const trimmed = name.trim();
    if (!trimmed) {
      throw new BadRequestException('精灵名字不能为空');
    }
    if (trimmed.length > 16) {
      throw new BadRequestException('精灵名字不能超过 16 个字');
    }
    const couple = await this.getActiveCoupleForUser(userId);
    const spirit = await this.prisma.coupleSpirit.upsert({
      where: { coupleId: couple.id },
      create: {
        coupleId: couple.id,
        name: trimmed,
        style: SpiritStyle.FLAME,
        appearance: this.appearanceFor(SpiritStyle.FLAME, SpiritStage.BABY),
      },
      update: { name: trimmed },
    });
    return this.spiritPayload(this.withDisplayMood(spirit));
  }

  async updateSpiritStyle(userId: string, style: SpiritStyle) {
    if (!Object.values(SpiritStyle).includes(style)) {
      throw new BadRequestException('精灵款式不正确');
    }
    const couple = await this.getActiveCoupleForUser(userId);
    const current = await this.prisma.coupleSpirit.upsert({
      where: { coupleId: couple.id },
      create: {
        coupleId: couple.id,
        style,
        appearance: this.appearanceFor(style, SpiritStage.BABY),
      },
      update: {},
    });
    const spirit = await this.prisma.coupleSpirit.update({
      where: { coupleId: couple.id },
      data: {
        style,
        appearance: this.appearanceFor(style, current.stage),
        mood: SpiritMood.HAPPY,
      },
    });
    return this.spiritPayload(this.withDisplayMood(spirit));
  }

  async listLogs(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    return this.prisma.spiritGrowthLog.findMany({
      where: { coupleId: couple.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async getPoints(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    return this.prisma.$transaction((tx) => this.ensurePointAccount(tx, couple.id));
  }

  async listPointTransactions(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    return this.prisma.pointTransaction.findMany({
      where: { coupleId: couple.id },
      orderBy: { createdAt: 'desc' },
      take: 80,
    });
  }

  async getCheckinStatus(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    return this.getCheckinStatusInTx(this.prisma, userId, couple.id);
  }

  async checkin(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    return this.prisma.$transaction(async (tx) => {
      await this.ensureSpirit(tx, couple.id);
      const account = await this.ensurePointAccount(tx, couple.id);
      const checkinDate = this.todayShanghai();
      const existing = await tx.checkin.findUnique({
        where: { userId_checkinDate: { userId, checkinDate } },
      });
      if (existing) {
        return {
          alreadyCheckedIn: true,
          checkin: existing,
          points: account,
          status: await this.getCheckinStatusInTx(tx, userId, couple.id),
        };
      }

      const yesterday = this.addDays(checkinDate, -1);
      const previous = await tx.checkin.findUnique({
        where: { userId_checkinDate: { userId, checkinDate: yesterday } },
      });
      const streakDays = previous ? previous.streakDays + 1 : 1;
      const base = POINT_REWARDS.CHECKIN.points;
      const bonus =
        streakDays % 14 === 0 ? 40 : streakDays % 7 === 0 ? 20 : streakDays % 3 === 0 ? 5 : 0;
      const pointsEarned = base + bonus;

      const checkin = await tx.checkin.create({
        data: { userId, coupleId: couple.id, checkinDate, streakDays, pointsEarned },
      });
      const points = await this.earnPoints(tx, {
        coupleId: couple.id,
        userId,
        reason: PointReason.CHECKIN,
        amount: pointsEarned,
        relatedType: 'checkin',
        relatedId: checkin.id,
        skipDuplicateCheck: true,
      });
      await tx.spiritGrowthLog.create({
        data: {
          coupleId: couple.id,
          userId,
          type: SpiritLogType.CHECKIN,
          content: `今天签到获得 ${pointsEarned} 积分。`,
          metadata: { streakDays, base, bonus },
        },
      });
      const spirit = await tx.coupleSpirit.update({
        where: { coupleId: couple.id },
        data: { mood: SpiritMood.HAPPY },
      });
      return {
        alreadyCheckedIn: false,
        checkin,
        points,
        spirit: this.spiritPayload(this.withDisplayMood(spirit)),
        status: await this.getCheckinStatusInTx(tx, userId, couple.id),
      };
    });
  }

  async feed(userId: string, feedType: FeedType) {
    const rule = FEED_RULES[feedType];
    if (!rule) {
      throw new BadRequestException('喂养类型不正确');
    }
    const couple = await this.getActiveCoupleForUser(userId);
    return this.prisma.$transaction(async (tx) => {
      const account = await this.ensurePointAccount(tx, couple.id);
      const current = await this.ensureSpirit(tx, couple.id);
      if (account.balance < rule.points) {
        throw new BadRequestException('积分不足，暂时不能喂养精灵');
      }

      const leveled = this.applyExp(current.level, current.exp, rule.exp);
      const oldStage = current.stage;
      const nextStage = this.stageForLevel(leveled.level);
      const nextSpirit = await tx.coupleSpirit.update({
        where: { coupleId: couple.id },
        data: {
          level: leveled.level,
          exp: leveled.exp,
          stage: nextStage,
          appearance: this.appearanceFor(current.style, nextStage),
          mood: leveled.levelUp ? SpiritMood.EXCITED : SpiritMood.HAPPY,
          lastFedAt: new Date(),
        },
      });

      const points = await tx.pointAccount.update({
        where: { coupleId: couple.id },
        data: {
          balance: { decrement: rule.points },
          totalSpent: { increment: rule.points },
        },
      });
      await tx.pointTransaction.create({
        data: {
          coupleId: couple.id,
          userId,
          type: PointTransactionType.SPEND,
          amount: -rule.points,
          balanceAfter: points.balance,
          reason: PointReason.FEED_SPIRIT,
          relatedType: 'feed',
          relatedId: `${feedType}-${Date.now()}`,
        },
      });
      await tx.spiritGrowthLog.create({
        data: {
          coupleId: couple.id,
          userId,
          type: SpiritLogType.FEED,
          content: `${rule.label}成功，精灵经验 +${rule.exp}。`,
          metadata: { feedType, points: rule.points, exp: rule.exp },
        },
      });
      if (leveled.levelUp) {
        await tx.spiritGrowthLog.create({
          data: {
            coupleId: couple.id,
            userId,
            type: SpiritLogType.LEVEL_UP,
            content: `精灵升到了 Lv.${leveled.level}。`,
            metadata: { fromLevel: current.level, toLevel: leveled.level },
          },
        });
      }
      if (oldStage !== nextStage) {
        await tx.spiritGrowthLog.create({
          data: {
            coupleId: couple.id,
            userId,
            type: SpiritLogType.STAGE_CHANGED,
            content: `精灵进入了${this.stageText(nextStage)}。`,
            metadata: { fromStage: oldStage, toStage: nextStage },
          },
        });
      }
      return {
        spirit: this.spiritPayload(this.withDisplayMood(nextSpirit)),
        points,
        levelUp: leveled.levelUp,
        stageChanged: oldStage !== nextStage,
      };
    });
  }

  async awardForAction(input: {
    userId: string;
    reason: Exclude<PointReason, 'CHECKIN' | 'FEED_SPIRIT'>;
    relatedType: string;
    relatedId: string;
    coupleId?: string;
  }) {
    const couple = input.coupleId
      ? { id: input.coupleId }
      : await this.getActiveCoupleForUser(input.userId);
    const config = POINT_REWARDS[input.reason];
    if (!config) {
      return null;
    }
    return this.prisma.$transaction(async (tx) => {
      await this.ensurePointAccount(tx, couple.id);
      await this.ensureSpirit(tx, couple.id);
      const existing = await tx.pointTransaction.findUnique({
        where: {
          coupleId_userId_reason_relatedId: {
            coupleId: couple.id,
            userId: input.userId,
            reason: input.reason,
            relatedId: input.relatedId,
          },
        },
      });
      if (existing) {
        return null;
      }
      if (config.dailyLimit) {
        const count = await tx.pointTransaction.count({
          where: {
            coupleId: couple.id,
            userId: input.userId,
            reason: input.reason,
            createdAt: { gte: this.todayShanghai(), lt: this.addDays(this.todayShanghai(), 1) },
          },
        });
        if (count >= config.dailyLimit) {
          return null;
        }
      }
      const account = await this.earnPoints(tx, {
        coupleId: couple.id,
        userId: input.userId,
        reason: input.reason,
        amount: config.points,
        relatedType: input.relatedType,
        relatedId: input.relatedId,
      });
      if (input.reason === PointReason.FULFILL_WISH) {
        await tx.spiritGrowthLog.create({
          data: {
            coupleId: couple.id,
            userId: input.userId,
            type: SpiritLogType.WISH_FULFILLED,
            content: '你们完成了一次饭后兑现，精灵很开心。',
            metadata: { relatedId: input.relatedId },
          },
        });
        await tx.coupleSpirit.update({
          where: { coupleId: couple.id },
          data: { mood: SpiritMood.EXCITED },
        });
      }
      return account;
    });
  }

  private async earnPoints(
    tx: Tx,
    input: {
      coupleId: string;
      userId: string;
      reason: PointReason;
      amount: number;
      relatedType: string;
      relatedId: string;
      skipDuplicateCheck?: boolean;
    },
  ) {
    const account = await tx.pointAccount.update({
      where: { coupleId: input.coupleId },
      data: {
        balance: { increment: input.amount },
        totalEarned: { increment: input.amount },
      },
    });
    await tx.pointTransaction.create({
      data: {
        coupleId: input.coupleId,
        userId: input.userId,
        type: PointTransactionType.EARN,
        amount: input.amount,
        balanceAfter: account.balance,
        reason: input.reason,
        relatedType: input.relatedType,
        relatedId: input.relatedId,
      },
    });
    return account;
  }

  private async getActiveCoupleForUser(userId: string) {
    const couple = await this.prisma.couple.findFirst({
      where: {
        status: CoupleStatus.ACTIVE,
        OR: [{ userAId: userId }, { userBId: userId }],
      },
    });
    if (!couple) {
      throw new BadRequestException('请先完成双人绑定');
    }
    return couple;
  }

  private ensurePointAccount(tx: Tx, coupleId: string) {
    return tx.pointAccount.upsert({
      where: { coupleId },
      create: { coupleId },
      update: {},
    });
  }

  private ensureSpirit(tx: Tx, coupleId: string) {
    return tx.coupleSpirit.upsert({
      where: { coupleId },
      create: {
        coupleId,
        style: SpiritStyle.FLAME,
        appearance: this.appearanceFor(SpiritStyle.FLAME, SpiritStage.BABY),
      },
      update: {},
    });
  }

  private async getCheckinStatusInTx(tx: Pick<Tx, 'checkin'>, userId: string, coupleId: string) {
    const today = this.todayShanghai();
    const yesterday = this.addDays(today, -1);
    const todayRecord = await tx.checkin.findUnique({
      where: { userId_checkinDate: { userId, checkinDate: today } },
    });
    const latest = await tx.checkin.findFirst({
      where: { userId, coupleId },
      orderBy: { checkinDate: 'desc' },
    });
    const activeStreak =
      latest &&
      (latest.checkinDate.getTime() === today.getTime() ||
        latest.checkinDate.getTime() === yesterday.getTime())
        ? latest.streakDays
        : 0;
    return {
      checkedInToday: Boolean(todayRecord),
      streakDays: activeStreak,
      todayPoints: todayRecord?.pointsEarned ?? 0,
      checkinDate: today,
    };
  }

  private applyExp(level: number, exp: number, addedExp: number) {
    let nextLevel = level;
    let nextExp = exp + addedExp;
    let levelUp = false;
    while (nextExp >= this.expToNextLevel(nextLevel)) {
      nextExp -= this.expToNextLevel(nextLevel);
      nextLevel += 1;
      levelUp = true;
    }
    return { level: nextLevel, exp: nextExp, levelUp };
  }

  private expToNextLevel(level: number) {
    if (level === 1) return 50;
    if (level === 2) return 80;
    if (level === 3) return 120;
    if (level === 4) return 160;
    let required = 160;
    for (let current = 5; current <= level; current += 1) {
      required = Math.ceil(required * 1.25);
    }
    return required;
  }

  private stageForLevel(level: number) {
    if (level >= 8) return SpiritStage.INTIMATE;
    if (level >= 4) return SpiritStage.GROWING;
    return SpiritStage.BABY;
  }

  private appearanceFor(style: SpiritStyle, stage: SpiritStage) {
    const styleKey = style.toLowerCase();
    if (stage === SpiritStage.INTIMATE) return `${styleKey}_intimate`;
    if (stage === SpiritStage.GROWING) return `${styleKey}_growing`;
    return `${styleKey}_baby`;
  }

  private withDisplayMood<T extends { lastFedAt: Date | null; mood: SpiritMood }>(spirit: T) {
    if (spirit.lastFedAt) {
      const hoursSinceFed = Date.now() - spirit.lastFedAt.getTime();
      if (hoursSinceFed > 24 * 60 * 60 * 1000 && spirit.mood !== SpiritMood.EXCITED) {
        return { ...spirit, mood: SpiritMood.HUNGRY };
      }
    }
    return spirit;
  }

  private spiritPayload(spirit: {
    id: string;
    name: string;
    level: number;
    exp: number;
    stage: SpiritStage;
    mood: SpiritMood;
    style: SpiritStyle;
    appearance: string;
    lastFedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      ...spirit,
      expToNextLevel: this.expToNextLevel(spirit.level),
    };
  }

  private stageText(stage: SpiritStage) {
    if (stage === SpiritStage.INTIMATE) return '亲密期';
    if (stage === SpiritStage.GROWING) return '成长期';
    return '幼年期';
  }

  private todayShanghai() {
    const now = new Date();
    const shanghai = new Date(now.getTime() + SHANGHAI_OFFSET_MS);
    return new Date(Date.UTC(shanghai.getUTCFullYear(), shanghai.getUTCMonth(), shanghai.getUTCDate()) - SHANGHAI_OFFSET_MS);
  }

  private addDays(date: Date, days: number) {
    return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
  }
}
