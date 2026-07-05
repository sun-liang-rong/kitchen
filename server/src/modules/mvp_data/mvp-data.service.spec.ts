import { JwtService } from "@nestjs/jwt";
import { AuthService } from "../auth/auth.service";
import { CouplesService } from "../couples/couples.service";
import { MvpDataService } from "./mvp-data.service";
import { PrismaService } from "../../prisma/prisma.service";

describe("MvpDataService", () => {
  let service: MvpDataService;
  let prisma: PrismaService;
  let authService: AuthService;
  let couplesService: CouplesService;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    service = new MvpDataService(prisma);
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
    await service.resetDemoData();
  });

  it("runs the wish response confirmation fulfillment dish loop against postgres", async () => {
    const wish = await service.createWish({
      creatorId: "me",
      title: "糖醋排骨",
      desiredTime: "WEEKEND",
      intensity: "WEEKEND_PLAN",
      helperTasks: ["买菜", "洗碗"],
    });

    expect(wish.status).toBe("IN_POOL");

    const responded = await service.respondToWish(wish.id, {
      responderId: "partner",
      responseType: "LIGHT_VERSION",
      proposedTitle: "可乐鸡翅",
      reasonTags: ["今天有点累"],
    });

    expect(responded.status).toBe("PENDING_CONFIRMATION");
    expect(responded.currentResponse?.confirmedAt).toBeNull();

    const confirmed = await service.confirmResponse(
      responded.currentResponse!.id,
    );
    expect(confirmed.status).toBe("CLAIMED");

    const result = await service.fulfillWish(wish.id, {
      fulfillerId: "partner",
      actualDishName: "可乐鸡翅",
      helperTasksDone: ["洗碗"],
      feedbackTags: ["今天很好吃"],
      addToDishes: true,
    });

    expect(result.wish.status).toBe("FULFILLED");
    await expect(service.listFulfillments()).resolves.toHaveLength(1);
    const dishes = await service.listDishes();
    expect(dishes.some((dish) => dish.name === "可乐鸡翅")).toBe(true);
  });

  it("runs the full real-user regression loop from register and bind to favorite dish", async () => {
    await service.resetDemoData();

    const inviter = await authService.register({
      email: "loop-a@example.com",
      password: "secret123",
      nickname: "Loop A",
    });
    const invitee = await authService.register({
      email: "loop-b@example.com",
      password: "secret123",
      nickname: "Loop B",
    });

    const loggedIn = await authService.login({
      email: "loop-a@example.com",
      password: "secret123",
    });
    expect(loggedIn.user.id).toBe(inviter.user.id);

    const code = await couplesService.generateCode(inviter.user.id);
    const application = await couplesService.applyByCode(
      invitee.user.id,
      code.code,
    );
    const binding = await couplesService.accept(
      inviter.user.id,
      application.id,
    );
    expect(binding.status).toBe("BOUND");

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
  });

  it("keeps real bound couple data isolated from the demo couple", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: { email: "real-a@example.com", nickname: "真实A" },
    });
    const userB = await prisma.user.create({
      data: { email: "real-b@example.com", nickname: "真实B" },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const wish = await service.createWishForUser(userA.id, {
      title: "番茄牛腩",
      desiredTime: "WEEKEND",
      intensity: "WEEKEND_PLAN",
    });
    expect(wish.creatorId).toBe(userA.id);

    const realWishes = await service.listWishesForUser(userB.id);
    expect(realWishes.map((item) => item.title)).toContain("番茄牛腩");

    const demoWishes = await service.listWishes();
    expect(demoWishes.map((item) => item.title)).not.toContain("番茄牛腩");
  });

  it("filters wishes by creator scope for a bound couple", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: { email: "scope-a@example.com", nickname: "Scope A" },
    });
    const userB = await prisma.user.create({
      data: { email: "scope-b@example.com", nickname: "Scope B" },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    await service.createWishForUser(userA.id, { title: "我想喝汤" });
    await service.createWishForUser(userB.id, { title: "她想吃面" });

    const mine = await service.listWishesForUser(userA.id, undefined, "me");
    const partners = await service.listWishesForUser(
      userA.id,
      undefined,
      "partner",
    );

    expect(mine.map((wish) => wish.title)).toEqual(["我想喝汤"]);
    expect(partners.map((wish) => wish.title)).toEqual(["她想吃面"]);
  });

  it("creates a notification for the partner when a real user creates a wish", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: { email: "notice-a@example.com", nickname: "Notice A" },
    });
    const userB = await prisma.user.create({
      data: { email: "notice-b@example.com", nickname: "Notice B" },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const wish = await service.createWishForUser(userA.id, {
      title: "想吃锅包肉",
    });
    const notifications = await prisma.notification.findMany({
      where: { userId: userB.id, relatedId: wish.id },
    });

    expect(notifications).toHaveLength(1);
    expect(notifications[0].title).toBe("有新的吃饭愿望");
  });

  it("searches dishes by name and tags", async () => {
    await service.resetDemoData();
    await service.createDish({
      name: "青椒肉丝",
      tasteTags: ["下饭"],
      suitableTimeTags: ["TONIGHT"],
    });
    await service.createDish({
      name: "冬瓜汤",
      tasteTags: ["清淡"],
      suitableTimeTags: ["THIS_WEEK"],
    });

    const byName = await service.listDishes({ q: "青椒" });
    expect(byName.map((dish) => dish.name)).toContain("青椒肉丝");
    expect(byName.map((dish) => dish.name)).not.toContain("冬瓜汤");

    const byTag = await service.listDishes({ q: "清淡" });
    expect(byTag.map((dish) => dish.name)).toContain("冬瓜汤");
  });

  it("filters dishes by difficulty and favorite flag", async () => {
    await service.resetDemoData();
    await service.createDish({
      name: "快手炒蛋",
      difficulty: "EASY",
      isFavorite: true,
    });
    await service.createDish({
      name: "慢炖牛腩",
      difficulty: "HARD",
      isFavorite: false,
    });

    const easyFavorites = await service.listDishes({
      difficulty: "EASY",
      isFavorite: true,
    });

    expect(easyFavorites.map((dish) => dish.name)).toContain("快手炒蛋");
    expect(easyFavorites.map((dish) => dish.name)).not.toContain("慢炖牛腩");
  });

  it("deletes only the current user unfulfilled wish", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: { email: "delete-a@example.com", nickname: "Delete A" },
    });
    const userB = await prisma.user.create({
      data: { email: "delete-b@example.com", nickname: "Delete B" },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const wish = await service.createWishForUser(userA.id, {
      title: "想撤回的愿望",
    });
    await expect(service.deleteWishForUser(userB.id, wish.id)).rejects.toThrow(
      "只能删除自己许下的愿望",
    );

    await expect(service.deleteWishForUser(userA.id, wish.id)).resolves.toEqual(
      {
        deleted: true,
        id: wish.id,
      },
    );
    await expect(service.getWishForUser(userA.id, wish.id)).rejects.toThrow(
      "愿望不存在",
    );
  });

  it("reopens a pending response back to the pool", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: { email: "reopen-a@example.com", nickname: "Reopen A" },
    });
    const userB = await prisma.user.create({
      data: { email: "reopen-b@example.com", nickname: "Reopen B" },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const wish = await service.createWishForUser(userA.id, {
      title: "想吃鱼香肉丝",
    });
    const responded = await service.respondToWishForUser(userB.id, wish.id, {
      responseType: "LIGHT_VERSION",
      proposedTitle: "青椒肉丝",
    });

    await expect(
      service.reopenResponseForUser(userB.id, responded.currentResponse!.id),
    ).rejects.toThrow("只有许愿人可以让愿望继续商量");

    const reopened = await service.reopenResponseForUser(
      userA.id,
      responded.currentResponse!.id,
    );
    expect(reopened.status).toBe("IN_POOL");
    expect(reopened.currentResponseId).toBeNull();
  });

  it("rejects responding to wishes that are already waiting or arranged", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: {
        email: "respond-state-a@example.com",
        nickname: "Respond State A",
      },
    });
    const userB = await prisma.user.create({
      data: {
        email: "respond-state-b@example.com",
        nickname: "Respond State B",
      },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const wish = await service.createWishForUser(userA.id, {
      title: "想吃红烧肉",
    });
    await service.respondToWishForUser(userB.id, wish.id, {
      responseType: "LIGHT_VERSION",
      proposedTitle: "青椒肉丝",
    });

    await expect(
      service.respondToWishForUser(userB.id, wish.id, {
        responseType: "ALTERNATIVE",
        proposedTitle: "可乐鸡翅",
      }),
    ).rejects.toThrow("只有池中或先搁着的愿望可以继续回应");

    const shelvedWish = await service.createWishForUser(userA.id, {
      title: "想喝汤",
    });
    await service.respondToWishForUser(userB.id, shelvedWish.id, {
      responseType: "SHELVE",
    });
    await expect(
      service.respondToWishForUser(userB.id, shelvedWish.id, {
        responseType: "FULFILL_TONIGHT",
      }),
    ).resolves.toMatchObject({ status: "CLAIMED" });
  });

  it("only confirms or reopens the current pending response", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: {
        email: "current-response-a@example.com",
        nickname: "Current Response A",
      },
    });
    const userB = await prisma.user.create({
      data: {
        email: "current-response-b@example.com",
        nickname: "Current Response B",
      },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const wish = await service.createWishForUser(userA.id, {
      title: "想吃牛腩",
    });
    const first = await service.respondToWishForUser(userB.id, wish.id, {
      responseType: "LIGHT_VERSION",
      proposedTitle: "番茄鸡蛋面",
    });
    const firstResponseId = first.currentResponse!.id;
    await service.reopenResponseForUser(userA.id, firstResponseId);

    await expect(
      service.confirmResponseForUser(userA.id, firstResponseId),
    ).rejects.toThrow("只有待确认的回应可以这样处理");
    await expect(
      service.reopenResponseForUser(userA.id, firstResponseId),
    ).rejects.toThrow("只有待确认的回应可以这样处理");

    const second = await service.respondToWishForUser(userB.id, wish.id, {
      responseType: "ALTERNATIVE",
      proposedTitle: "可乐鸡翅",
    });
    const staleResponse = await prisma.wishResponse.create({
      data: {
        wishId: wish.id,
        responderId: userB.id,
        responseType: "ALTERNATIVE",
        proposedTitle: "宫保鸡丁",
        reasonTags: [],
      },
    });

    await expect(
      service.confirmResponseForUser(userA.id, staleResponse.id),
    ).rejects.toThrow("只能处理当前等待确认的回应");
    await expect(
      service.reopenResponseForUser(userA.id, staleResponse.id),
    ).rejects.toThrow("只能处理当前等待确认的回应");

    await expect(
      service.confirmResponseForUser(userA.id, second.currentResponse!.id),
    ).resolves.toMatchObject({
      status: "CLAIMED",
    });
  });

  it("only fulfills wishes after an arrangement is confirmed", async () => {
    await service.resetDemoData();
    const userA = await prisma.user.create({
      data: {
        email: "fulfill-state-a@example.com",
        nickname: "Fulfill State A",
      },
    });
    const userB = await prisma.user.create({
      data: {
        email: "fulfill-state-b@example.com",
        nickname: "Fulfill State B",
      },
    });
    await prisma.couple.create({
      data: { userAId: userA.id, userBId: userB.id },
    });

    const inPoolWish = await service.createWishForUser(userA.id, {
      title: "想吃排骨",
    });
    await expect(
      service.fulfillWishForUser(userB.id, inPoolWish.id, {
        actualDishName: "糖醋排骨",
      }),
    ).rejects.toThrow("只有已确认安排的愿望可以记录兑现");

    const pendingWish = await service.createWishForUser(userA.id, {
      title: "想吃鸡翅",
    });
    await service.respondToWishForUser(userB.id, pendingWish.id, {
      responseType: "ALTERNATIVE",
      proposedTitle: "红烧鸡腿",
    });
    await expect(
      service.fulfillWishForUser(userB.id, pendingWish.id, {
        actualDishName: "红烧鸡腿",
      }),
    ).rejects.toThrow("只有已确认安排的愿望可以记录兑现");

    const shelvedWish = await service.createWishForUser(userA.id, {
      title: "想吃火锅",
    });
    await service.respondToWishForUser(userB.id, shelvedWish.id, {
      responseType: "SHELVE",
    });
    await expect(
      service.fulfillWishForUser(userB.id, shelvedWish.id, {
        actualDishName: "火锅",
      }),
    ).rejects.toThrow("只有已确认安排的愿望可以记录兑现");

    const arrangedWish = await service.createWishForUser(userA.id, {
      title: "想喝鸡汤",
    });
    await service.respondToWishForUser(userB.id, arrangedWish.id, {
      responseType: "FULFILL_TONIGHT",
    });
    await expect(
      service.fulfillWishForUser(userB.id, arrangedWish.id, {
        actualDishName: "鸡汤",
      }),
    ).resolves.toMatchObject({ wish: { status: "FULFILLED" } });
  });
});
