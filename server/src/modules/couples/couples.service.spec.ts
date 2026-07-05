import { PrismaService } from '../../prisma/prisma.service';
import { CouplesService } from './couples.service';

describe('CouplesService', () => {
  let prisma: PrismaService;
  let service: CouplesService;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    service = new CouplesService(prisma);
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  beforeEach(async () => {
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

  it('binds two users by invite code and prevents duplicate binding', async () => {
    const inviter = await prisma.user.create({
      data: { email: 'a@example.com', nickname: 'A' },
    });
    const invitee = await prisma.user.create({
      data: { email: 'b@example.com', nickname: 'B' },
    });

    const code = await service.generateCode(inviter.id);
    await expect(service.status(inviter.id)).resolves.toMatchObject({
      status: 'UNBOUND',
    });

    const application = await service.applyByCode(invitee.id, code.code);
    expect(application.inviteeId).toBe(invitee.id);
    await expect(service.status(invitee.id)).resolves.toMatchObject({
      status: 'PENDING',
    });
    await expect(service.status(inviter.id)).resolves.toMatchObject({
      status: 'WAITING_FOR_ME',
    });

    const couple = await service.accept(inviter.id, application.id);
    expect(couple.couple.userAId).toBe(inviter.id);
    expect(couple.couple.userBId).toBe(invitee.id);
    expect(couple.partner.id).toBe(invitee.id);

    await expect(service.generateCode(inviter.id)).rejects.toThrow('已绑定用户不能重复绑定');
    await expect(service.status(invitee.id)).resolves.toMatchObject({
      status: 'BOUND',
    });
  });

  it('unbinds an active couple', async () => {
    const userA = await prisma.user.create({
      data: { email: 'c@example.com', nickname: 'C' },
    });
    const userB = await prisma.user.create({
      data: { email: 'd@example.com', nickname: 'D' },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const unbound = await service.unbind(userA.id);
    expect(unbound.status).toBe('UNBOUND');
    await expect(service.status(userA.id)).resolves.toMatchObject({
      status: 'UNBOUND',
    });
  });
});
