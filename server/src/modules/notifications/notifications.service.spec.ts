import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from './notifications.service';

describe('NotificationsService', () => {
  let prisma: PrismaService;
  let service: NotificationsService;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    service = new NotificationsService(prisma);
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

  it('lists unread notifications and marks them read', async () => {
    const user = await prisma.user.create({
      data: { email: 'notify@example.com', nickname: '通知用户' },
    });
    const notification = await prisma.notification.create({
      data: {
        userId: user.id,
        type: NotificationType.WISH_CREATED,
        title: '新愿望',
        content: '对方许了一个愿望',
      },
    });

    await expect(service.unreadCount(user.id)).resolves.toEqual({ count: 1 });
    await expect(service.list(user.id, true)).resolves.toHaveLength(1);

    const read = await service.markRead(user.id, notification.id);
    expect(read.readAt).toBeTruthy();
    await expect(service.unreadCount(user.id)).resolves.toEqual({ count: 0 });
  });
});
