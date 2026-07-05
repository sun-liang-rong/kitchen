import { PrismaService } from "../../prisma/prisma.service";
import { UsersService } from "./users.service";

describe("UsersService", () => {
  let prisma: PrismaService;
  let service: UsersService;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    service = new UsersService(prisma);
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

  it("updates the current user profile only", async () => {
    const user = await prisma.user.create({
      data: { email: "profile@example.com", nickname: "旧昵称" },
    });

    const updated = await service.updateMe(user.id, {
      nickname: "新昵称",
      avatarUrl: "https://example.com/avatar.png",
    });

    expect(updated).toMatchObject({
      id: user.id,
      nickname: "新昵称",
      avatarUrl: "https://example.com/avatar.png",
    });
    await expect(service.me(user.id)).resolves.toMatchObject({
      nickname: "新昵称",
    });

    const cleared = await service.updateMe(user.id, {
      avatarUrl: "",
    });
    expect(cleared.avatarUrl).toBeNull();
  });
});
