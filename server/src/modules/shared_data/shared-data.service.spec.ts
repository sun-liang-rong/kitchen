import { JwtService } from "@nestjs/jwt";
import { AuthService } from "../auth/auth.service";
import { CouplesService } from "../couples/couples.service";
import { SharedDataService } from "./shared-data.service";
import { PrismaService } from "../../prisma/prisma.service";

describe("SharedDataService", () => {
  let service: SharedDataService;
  let prisma: PrismaService;
  let authService: AuthService;
  let couplesService: CouplesService;
  let pairIndex = 0;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    service = new SharedDataService(prisma, {
      awardForAction: jest.fn(),
    } as never);
    authService = new AuthService(
      prisma,
      new JwtService({
        secret: process.env.JWT_SECRET ?? "dev-kitchen-wish-well-secret",
        signOptions: { expiresIn: "30d" },
      }),
    );
    couplesService = new CouplesService(prisma);
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    await resetDatabase();
  });

  async function resetDatabase() {
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
  }

  async function createBoundPair(prefix = "pair") {
    pairIndex += 1;
    const inviter = await authService.register({
      email: `${prefix}-${pairIndex}-a@example.com`,
      password: "secret123",
      nickname: `${prefix} A`,
    });
    const invitee = await authService.register({
      email: `${prefix}-${pairIndex}-b@example.com`,
      password: "secret123",
      nickname: `${prefix} B`,
    });
    const code = await couplesService.generateCode(inviter.user.id);
    const application = await couplesService.applyByCode(
      invitee.user.id,
      code.code,
    );
    const binding = await couplesService.accept(
      inviter.user.id,
      application.id,
    );
    return { inviter, invitee, binding };
  }

  it("runs the real-user wish response confirmation fulfillment dish loop", async () => {
    const { inviter, invitee } = await createBoundPair("loop");
    const loggedIn = await authService.login({
      email: inviter.user.email!,
      password: "secret123",
    });
    expect(loggedIn.user.id).toBe(inviter.user.id);

    const wish = await service.createWishForUser(inviter.user.id, {
      title: "糖醋排骨",
      desiredTime: "WEEKEND",
      intensity: "WEEKEND_PLAN",
      helperTasks: ["买菜", "洗碗"],
    });
    expect(wish.status).toBe("IN_POOL");

    const responded = await service.respondToWishForUser(
      invitee.user.id,
      wish.id,
      {
        responseType: "LIGHT_VERSION",
        proposedTitle: "可乐鸡翅",
        reasonTags: ["今天有点累"],
      },
    );
    expect(responded.status).toBe("PENDING_CONFIRMATION");

    const confirmed = await service.confirmResponseForUser(
      inviter.user.id,
      responded.currentResponse!.id,
    );
    expect(confirmed.status).toBe("CLAIMED");

    const result = await service.fulfillWishForUser(invitee.user.id, wish.id, {
      actualDishName: "可乐鸡翅",
      helperTasksDone: ["洗碗"],
      feedbackTags: ["今天很好吃", "可以进常吃"],
      addToDishes: true,
      imageUrl: "/uploads/dishes/coke-chicken.webp",
    });
    expect(result.wish.status).toBe("FULFILLED");

    const fulfillments = await service.listFulfillmentsForUser(inviter.user.id);
    expect(fulfillments.map((item) => item.actualDishName)).toContain(
      "可乐鸡翅",
    );

    const dishes = await service.listDishesForUser(inviter.user.id, {
      isFavorite: true,
    });
    expect(dishes.map((dish) => dish.name)).toContain("可乐鸡翅");
    expect(dishes.find((dish) => dish.name === "可乐鸡翅")?.imageUrl).toBe(
      "/uploads/dishes/coke-chicken.webp",
    );
  });

  it("creates and updates dish image urls", async () => {
    const { inviter } = await createBoundPair("dish-image");

    const dish = await service.createDishForUser(inviter.user.id, {
      name: "红烧肉",
      imageUrl: "/uploads/dishes/braised-pork.jpg",
    });
    expect(dish.imageUrl).toBe("/uploads/dishes/braised-pork.jpg");

    const updated = await service.updateDishForUser(inviter.user.id, dish.id, {
      imageUrl: "/uploads/dishes/braised-pork-new.webp",
    });
    expect(updated.imageUrl).toBe("/uploads/dishes/braised-pork-new.webp");

    const cleared = await service.updateDishForUser(inviter.user.id, dish.id, {
      imageUrl: "",
    });
    expect(cleared.imageUrl).toBeNull();
  });

  it("keeps bound couple data isolated between couples", async () => {
    const pairA = await createBoundPair("isolated-a");
    const pairB = await createBoundPair("isolated-b");

    const wish = await service.createWishForUser(pairA.inviter.user.id, {
      title: "番茄牛腩",
      desiredTime: "WEEKEND",
      intensity: "WEEKEND_PLAN",
    });
    expect(wish.creatorId).toBe(pairA.inviter.user.id);

    const ownWishes = await service.listWishesForUser(pairA.invitee.user.id);
    expect(ownWishes.map((item) => item.title)).toContain("番茄牛腩");

    const otherWishes = await service.listWishesForUser(pairB.inviter.user.id);
    expect(otherWishes.map((item) => item.title)).not.toContain("番茄牛腩");
  });

  it("filters wishes by creator scope for a bound couple", async () => {
    const { inviter, invitee } = await createBoundPair("scope");

    await service.createWishForUser(inviter.user.id, { title: "我想喝汤" });
    await service.createWishForUser(invitee.user.id, { title: "她想吃面" });

    const mine = await service.listWishesForUser(
      inviter.user.id,
      undefined,
      "me",
    );
    const partners = await service.listWishesForUser(
      inviter.user.id,
      undefined,
      "partner",
    );

    expect(mine.map((wish) => wish.title)).toEqual(["我想喝汤"]);
    expect(partners.map((wish) => wish.title)).toEqual(["她想吃面"]);
  });

  it("creates a notification for the partner when a real user creates a wish", async () => {
    const { inviter, invitee } = await createBoundPair("notice");

    const wish = await service.createWishForUser(inviter.user.id, {
      title: "想吃锅包肉",
    });
    const notifications = await prisma.notification.findMany({
      where: { userId: invitee.user.id, relatedId: wish.id },
    });

    expect(notifications).toHaveLength(1);
    expect(notifications[0].title).toBe("有新的吃饭愿望");
  });

  it("searches dishes by name and tags", async () => {
    const { inviter } = await createBoundPair("search");

    await service.createDishForUser(inviter.user.id, {
      name: "青椒肉丝",
      tasteTags: ["下饭"],
      suitableTimeTags: ["TONIGHT"],
    });
    await service.createDishForUser(inviter.user.id, {
      name: "冬瓜汤",
      tasteTags: ["清淡"],
      suitableTimeTags: ["THIS_WEEK"],
    });

    const byName = await service.listDishesForUser(inviter.user.id, {
      q: "青椒",
    });
    expect(byName.map((dish) => dish.name)).toContain("青椒肉丝");
    expect(byName.map((dish) => dish.name)).not.toContain("冬瓜汤");

    const byTag = await service.listDishesForUser(inviter.user.id, {
      q: "清淡",
    });
    expect(byTag.map((dish) => dish.name)).toContain("冬瓜汤");
  });

  it("filters dishes by difficulty and favorite flag", async () => {
    const { inviter } = await createBoundPair("dish-filter");

    await service.createDishForUser(inviter.user.id, {
      name: "快手炒蛋",
      difficulty: "EASY",
      isFavorite: true,
    });
    await service.createDishForUser(inviter.user.id, {
      name: "慢炖牛腩",
      difficulty: "HARD",
      isFavorite: false,
    });

    const easyFavorites = await service.listDishesForUser(inviter.user.id, {
      difficulty: "EASY",
      isFavorite: true,
    });

    expect(easyFavorites.map((dish) => dish.name)).toContain("快手炒蛋");
    expect(easyFavorites.map((dish) => dish.name)).not.toContain("慢炖牛腩");
  });

  it("deletes only dishes from the current bound couple", async () => {
    const pairA = await createBoundPair("dish-delete-a");
    const pairB = await createBoundPair("dish-delete-b");

    const dish = await service.createDishForUser(pairA.inviter.user.id, {
      name: "酸辣土豆丝",
      isFavorite: true,
    });

    await expect(
      service.deleteDishForUser(pairB.inviter.user.id, dish.id),
    ).rejects.toThrow("菜不存在");

    await expect(
      service.deleteDishForUser(pairA.invitee.user.id, dish.id),
    ).resolves.toEqual({
      deleted: true,
      id: dish.id,
    });

    const dishes = await service.listDishesForUser(pairA.inviter.user.id);
    expect(dishes.map((item) => item.name)).not.toContain("酸辣土豆丝");
  });

  it("deletes only the current user unfulfilled wish", async () => {
    const { inviter, invitee } = await createBoundPair("delete");

    const wish = await service.createWishForUser(inviter.user.id, {
      title: "想撤回的愿望",
    });
    await expect(
      service.deleteWishForUser(invitee.user.id, wish.id),
    ).rejects.toThrow("只能删除自己许下的愿望");

    await expect(
      service.deleteWishForUser(inviter.user.id, wish.id),
    ).resolves.toEqual({
      deleted: true,
      id: wish.id,
    });
    await expect(
      service.getWishForUser(inviter.user.id, wish.id),
    ).rejects.toThrow("愿望不存在");
  });

  it("reopens a pending response back to the pool", async () => {
    const { inviter, invitee } = await createBoundPair("reopen");

    const wish = await service.createWishForUser(inviter.user.id, {
      title: "想吃鱼香肉丝",
    });
    const responded = await service.respondToWishForUser(
      invitee.user.id,
      wish.id,
      {
        responseType: "LIGHT_VERSION",
        proposedTitle: "青椒肉丝",
      },
    );

    await expect(
      service.reopenResponseForUser(
        invitee.user.id,
        responded.currentResponse!.id,
      ),
    ).rejects.toThrow("只有许愿人可以让愿望继续商量");

    const reopened = await service.reopenResponseForUser(
      inviter.user.id,
      responded.currentResponse!.id,
    );
    expect(reopened.status).toBe("IN_POOL");
    expect(reopened.currentResponseId).toBeNull();
  });

  it("rejects responding to wishes that are already waiting or arranged", async () => {
    const { inviter, invitee } = await createBoundPair("respond-state");

    const wish = await service.createWishForUser(inviter.user.id, {
      title: "想吃红烧肉",
    });
    await service.respondToWishForUser(invitee.user.id, wish.id, {
      responseType: "LIGHT_VERSION",
      proposedTitle: "青椒肉丝",
    });

    await expect(
      service.respondToWishForUser(invitee.user.id, wish.id, {
        responseType: "ALTERNATIVE",
        proposedTitle: "可乐鸡翅",
      }),
    ).rejects.toThrow("只有池中或先搁着的愿望可以继续回应");

    const shelvedWish = await service.createWishForUser(inviter.user.id, {
      title: "想喝汤",
    });
    await service.respondToWishForUser(invitee.user.id, shelvedWish.id, {
      responseType: "SHELVE",
    });
    await expect(
      service.respondToWishForUser(invitee.user.id, shelvedWish.id, {
        responseType: "FULFILL_TONIGHT",
      }),
    ).resolves.toMatchObject({ status: "CLAIMED" });
  });

  it("only confirms or reopens the current pending response", async () => {
    const { inviter, invitee } = await createBoundPair("current-response");

    const wish = await service.createWishForUser(inviter.user.id, {
      title: "想吃牛腩",
    });
    const first = await service.respondToWishForUser(invitee.user.id, wish.id, {
      responseType: "LIGHT_VERSION",
      proposedTitle: "番茄鸡蛋面",
    });
    const firstResponseId = first.currentResponse!.id;
    await service.reopenResponseForUser(inviter.user.id, firstResponseId);

    await expect(
      service.confirmResponseForUser(inviter.user.id, firstResponseId),
    ).rejects.toThrow("只有待确认的回应可以这样处理");
    await expect(
      service.reopenResponseForUser(inviter.user.id, firstResponseId),
    ).rejects.toThrow("只有待确认的回应可以这样处理");

    const second = await service.respondToWishForUser(
      invitee.user.id,
      wish.id,
      {
        responseType: "ALTERNATIVE",
        proposedTitle: "可乐鸡翅",
      },
    );
    const staleResponse = await prisma.wishResponse.create({
      data: {
        wishId: wish.id,
        responderId: invitee.user.id,
        responseType: "ALTERNATIVE",
        proposedTitle: "宫保鸡丁",
        reasonTags: [],
      },
    });

    await expect(
      service.confirmResponseForUser(inviter.user.id, staleResponse.id),
    ).rejects.toThrow("只能处理当前等待确认的回应");
    await expect(
      service.reopenResponseForUser(inviter.user.id, staleResponse.id),
    ).rejects.toThrow("只能处理当前等待确认的回应");

    await expect(
      service.confirmResponseForUser(
        inviter.user.id,
        second.currentResponse!.id,
      ),
    ).resolves.toMatchObject({
      status: "CLAIMED",
    });
  });

  it("only fulfills wishes after an arrangement is confirmed", async () => {
    const { inviter, invitee } = await createBoundPair("fulfill-state");

    const inPoolWish = await service.createWishForUser(inviter.user.id, {
      title: "想吃排骨",
    });
    await expect(
      service.fulfillWishForUser(invitee.user.id, inPoolWish.id, {
        actualDishName: "糖醋排骨",
      }),
    ).rejects.toThrow("只有已确认安排的愿望可以记录兑现");

    const pendingWish = await service.createWishForUser(inviter.user.id, {
      title: "想吃鸡翅",
    });
    await service.respondToWishForUser(invitee.user.id, pendingWish.id, {
      responseType: "ALTERNATIVE",
      proposedTitle: "红烧鸡腿",
    });
    await expect(
      service.fulfillWishForUser(invitee.user.id, pendingWish.id, {
        actualDishName: "红烧鸡腿",
      }),
    ).rejects.toThrow("只有已确认安排的愿望可以记录兑现");

    const shelvedWish = await service.createWishForUser(inviter.user.id, {
      title: "想吃火锅",
    });
    await service.respondToWishForUser(invitee.user.id, shelvedWish.id, {
      responseType: "SHELVE",
    });
    await expect(
      service.fulfillWishForUser(invitee.user.id, shelvedWish.id, {
        actualDishName: "火锅",
      }),
    ).rejects.toThrow("只有已确认安排的愿望可以记录兑现");

    const arrangedWish = await service.createWishForUser(inviter.user.id, {
      title: "想喝鸡汤",
    });
    await service.respondToWishForUser(invitee.user.id, arrangedWish.id, {
      responseType: "FULFILL_TONIGHT",
    });
    await expect(
      service.fulfillWishForUser(invitee.user.id, arrangedWish.id, {
        actualDishName: "鸡汤",
      }),
    ).resolves.toMatchObject({ wish: { status: "FULFILLED" } });
  });
});
