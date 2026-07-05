import { BadRequestException } from '@nestjs/common';
import { FeedType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { RewardsService } from './rewards.service';

describe('RewardsService', () => {
  let prisma: PrismaService;
  let service: RewardsService;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    service = new RewardsService(prisma);
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    await prisma.spiritGrowthLog.deleteMany({});
    await prisma.checkin.deleteMany({});
    await prisma.pointTransaction.deleteMany({});
    await prisma.pointAccount.deleteMany({});
    await prisma.coupleSpirit.deleteMany({});
    await prisma.notification.deleteMany({});
    await prisma.wishFulfillment.deleteMany({});
    await prisma.dish.deleteMany({});
    await prisma.wish.updateMany({ data: { currentResponseId: null } });
    await prisma.wishResponse.deleteMany({});
    await prisma.wish.deleteMany({});
    await prisma.kitchenStatus.deleteMany({});
    await prisma.coupleInvite.deleteMany({});
    await prisma.couple.deleteMany({});
    await prisma.user.deleteMany({});
  });

  it('creates spirit and points account for a bound couple', async () => {
    const { userA } = await createPair();

    const snapshot = await service.getSpirit(userA.id);

    expect(snapshot.spirit.level).toBe(1);
    expect(snapshot.spirit.appearance).toBe('flame_baby');
    expect(snapshot.spirit.style).toBe('FLAME');
    expect(snapshot.points.balance).toBe(0);
    expect(snapshot.checkin.checkedInToday).toBe(false);
  });

  it('checks in once per day and awards points only once', async () => {
    const { userA } = await createPair();

    const first = await service.checkin(userA.id);
    const second = await service.checkin(userA.id);

    expect(first.alreadyCheckedIn).toBe(false);
    expect(first.points.balance).toBe(10);
    expect(second.alreadyCheckedIn).toBe(true);
    expect(second.points.balance).toBe(10);
    await expect(prisma.pointTransaction.count()).resolves.toBe(1);
  });

  it('feeds the spirit and levels up when enough exp is gained', async () => {
    const { userA, couple } = await createPair();
    await service.checkin(userA.id);
    await prisma.pointAccount.update({
      where: { coupleId: couple.id },
      data: { balance: 100, totalEarned: 100 },
    });

    const result = await service.feed(userA.id, FeedType.FEAST);

    expect(result.levelUp).toBe(true);
    expect(result.spirit.level).toBe(2);
    expect(result.spirit.exp).toBe(50);
    expect(result.points.balance).toBe(20);
  });

  it('rejects feeding when points are insufficient', async () => {
    const { userA } = await createPair();
    await service.getSpirit(userA.id);

    await expect(service.feed(userA.id, FeedType.NORMAL)).rejects.toThrow(
      BadRequestException,
    );
  });

  async function createPair() {
    const userA = await prisma.user.create({
      data: { email: 'a@example.com', nickname: 'A' },
    });
    const userB = await prisma.user.create({
      data: { email: 'b@example.com', nickname: 'B' },
    });
    const couple = await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });
    return { userA, userB, couple };
  }
});
