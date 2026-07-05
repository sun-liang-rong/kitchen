import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CoupleStatus, InviteStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

type PublicUser = {
  id: string;
  nickname: string;
  email: string | null;
  phone: string | null;
  avatarUrl: string | null;
  gender: string;
};

@Injectable()
export class CouplesService {
  constructor(private readonly prisma: PrismaService) {}

  async status(userId: string) {
    const activeCouple = await this.findActiveCouple(userId);
    if (activeCouple) {
      const partner =
        activeCouple.userAId === userId ? activeCouple.userB : activeCouple.userA;
      const invite = await this.prisma.coupleInvite.findFirst({
        where: {
          coupleId: activeCouple.id,
          status: InviteStatus.ACCEPTED,
        },
        orderBy: { respondedAt: 'desc' },
        include: { inviter: { select: this.publicUserSelect() } },
      });
      return {
        status: 'BOUND',
        couple: activeCouple,
        partner,
        invite,
      };
    }

    const incoming = await this.prisma.coupleInvite.findFirst({
      where: {
        inviterId: userId,
        inviteeId: { not: null },
        status: InviteStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
      include: { inviter: { select: this.publicUserSelect() } },
    });
    if (incoming) {
      return { status: 'WAITING_FOR_ME', invite: incoming };
    }

    const outgoing = await this.prisma.coupleInvite.findFirst({
      where: {
        inviteeId: userId,
        status: InviteStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
      include: { inviter: { select: this.publicUserSelect() } },
    });
    if (outgoing) {
      return { status: 'PENDING', invite: outgoing };
    }

    const activeInvite = await this.prisma.coupleInvite.findFirst({
      where: {
        inviterId: userId,
        inviteeId: null,
        status: InviteStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
      include: { inviter: { select: this.publicUserSelect() } },
    });

    return { status: 'UNBOUND', invite: activeInvite };
  }

  async generateCode(userId: string) {
    await this.ensureCanBind(userId);

    const existing = await this.prisma.coupleInvite.findFirst({
      where: {
        inviterId: userId,
        inviteeId: null,
        status: InviteStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
    if (existing) {
      return existing;
    }

    return this.prisma.coupleInvite.create({
      data: {
        inviterId: userId,
        code: await this.createUniqueCode(),
        expiresAt: this.daysFromNow(7),
      },
    });
  }

  async applyByCode(userId: string, rawCode: string) {
    await this.ensureCanBind(userId);
    const code = rawCode.trim().toUpperCase();
    const invite = await this.prisma.coupleInvite.findUnique({
      where: { code },
      include: { inviter: { select: this.publicUserSelect() } },
    });
    if (!invite || invite.status !== InviteStatus.PENDING) {
      throw new NotFoundException('邀请码不存在或已失效');
    }
    if (invite.expiresAt <= new Date()) {
      await this.prisma.coupleInvite.update({
        where: { id: invite.id },
        data: { status: InviteStatus.EXPIRED },
      });
      throw new BadRequestException('邀请码已过期');
    }
    if (invite.inviterId === userId) {
      throw new BadRequestException('不能绑定自己');
    }
    await this.ensureCanBind(invite.inviterId);
    if (invite.inviteeId && invite.inviteeId !== userId) {
      throw new BadRequestException('邀请码已有待确认申请');
    }

    return this.prisma.coupleInvite.update({
      where: { id: invite.id },
      data: { inviteeId: userId },
      include: { inviter: { select: this.publicUserSelect() } },
    });
  }

  async accept(userId: string, inviteId: string) {
    await this.ensureCanBind(userId);
    const invite = await this.getPendingInvite(inviteId);
    if (invite.inviterId !== userId) {
      throw new BadRequestException('只有邀请码生成者可以同意绑定');
    }
    if (!invite.inviteeId) {
      throw new BadRequestException('还没有用户申请绑定');
    }
    await this.ensureCanBind(invite.inviteeId);

    const couple = await this.prisma.couple.create({
      data: {
        userAId: invite.inviterId,
        userBId: invite.inviteeId,
      },
      include: {
        userA: { select: this.publicUserSelect() },
        userB: { select: this.publicUserSelect() },
      },
    });

    await this.prisma.coupleInvite.update({
      where: { id: invite.id },
      data: {
        status: InviteStatus.ACCEPTED,
        coupleId: couple.id,
        respondedAt: new Date(),
      },
    });

    await this.prisma.coupleInvite.updateMany({
      where: {
        id: { not: invite.id },
        status: InviteStatus.PENDING,
        OR: [
          { inviterId: invite.inviterId },
          { inviterId: invite.inviteeId },
          { inviteeId: invite.inviterId },
          { inviteeId: invite.inviteeId },
        ],
      },
      data: { status: InviteStatus.CANCELLED, respondedAt: new Date() },
    });

    return this.bindingPayloadForUser(userId, couple);
  }

  async reject(userId: string, inviteId: string) {
    const invite = await this.getPendingInvite(inviteId);
    if (invite.inviterId !== userId) {
      throw new BadRequestException('只有邀请码生成者可以先不绑定');
    }
    return this.prisma.coupleInvite.update({
      where: { id: invite.id },
      data: { status: InviteStatus.REJECTED, respondedAt: new Date() },
    });
  }

  async cancel(userId: string, inviteId: string) {
    const invite = await this.getPendingInvite(inviteId);
    if (invite.inviteeId !== userId && invite.inviterId !== userId) {
      throw new BadRequestException('只能取消自己的绑定申请');
    }
    return this.prisma.coupleInvite.update({
      where: { id: invite.id },
      data: { status: InviteStatus.CANCELLED, respondedAt: new Date() },
    });
  }

  async unbind(userId: string) {
    const couple = await this.findActiveCouple(userId);
    if (!couple) {
      throw new BadRequestException('当前没有已绑定关系');
    }

    return this.prisma.couple.update({
      where: { id: couple.id },
      data: { status: CoupleStatus.UNBOUND },
      include: {
        userA: { select: this.publicUserSelect() },
        userB: { select: this.publicUserSelect() },
      },
    });
  }

  private async ensureCanBind(userId: string) {
    const activeCouple = await this.findActiveCouple(userId);
    if (activeCouple) {
      throw new BadRequestException('已绑定用户不能重复绑定');
    }
  }

  private async findActiveCouple(userId: string) {
    return this.prisma.couple.findFirst({
      where: {
        status: CoupleStatus.ACTIVE,
        OR: [{ userAId: userId }, { userBId: userId }],
      },
      include: {
        userA: { select: this.publicUserSelect() },
        userB: { select: this.publicUserSelect() },
      },
    });
  }

  private async getPendingInvite(inviteId: string) {
    const invite = await this.prisma.coupleInvite.findUnique({ where: { id: inviteId } });
    if (!invite || invite.status !== InviteStatus.PENDING || invite.expiresAt <= new Date()) {
      throw new NotFoundException('绑定申请不存在或已失效');
    }
    return invite;
  }

  private async createUniqueCode() {
    for (let index = 0; index < 5; index += 1) {
      const code = Math.random().toString(36).slice(2, 8).toUpperCase();
      const existing = await this.prisma.coupleInvite.findUnique({ where: { code } });
      if (!existing) {
        return code;
      }
    }
    throw new BadRequestException('邀请码生成失败，请重试');
  }

  private daysFromNow(days: number) {
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date;
  }

  private publicUserSelect() {
    return {
      id: true,
      nickname: true,
      email: true,
      phone: true,
      avatarUrl: true,
      gender: true,
    };
  }

  private bindingPayloadForUser(
    userId: string,
    couple: {
      id: string;
      userAId: string;
      userBId: string;
      userA: PublicUser;
      userB: PublicUser;
    },
  ) {
    const partner = couple.userAId === userId ? couple.userB : couple.userA;
    return {
      status: 'BOUND',
      couple,
      partner,
    };
  }
}
