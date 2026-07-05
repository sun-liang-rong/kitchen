import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let prisma: PrismaService;
  let service: AuthService;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    service = new AuthService(
      prisma,
      new JwtService({
        secret: process.env.JWT_SECRET ?? 'dev-kitchen-wish-well-secret',
        signOptions: { expiresIn: '30d' },
      }),
    );
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

  it('registers, logs in, and returns the current user', async () => {
    const registered = await service.register({
      email: 'one@example.com',
      password: 'secret123',
      nickname: '一号',
    });

    expect(registered.token).toBeTruthy();
    expect(registered.user.email).toBe('one@example.com');

    const loggedIn = await service.login({
      email: 'one@example.com',
      password: 'secret123',
    });
    expect(loggedIn.user.id).toBe(registered.user.id);

    await expect(service.me(registered.user.id)).resolves.toMatchObject({
      nickname: '一号',
    });
  });
});
