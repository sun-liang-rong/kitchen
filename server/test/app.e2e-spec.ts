import { ValidationPipe } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { Test } from "@nestjs/testing";
import { NestExpressApplication } from "@nestjs/platform-express";
import { join } from "path";
import * as request from "supertest";
import { AppModule } from "../src/app.module";
import { HttpExceptionFilter } from "../src/common/filters/http-exception.filter";
import { ResponseInterceptor } from "../src/common/interceptors/response.interceptor";
import { PrismaService } from "../src/prisma/prisma.service";

type ApiBody<T> = {
  code: number;
  message: string;
  data: T;
};

describe("Kitchen Wish Well API flow (e2e)", () => {
  let app: NestExpressApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication<NestExpressApplication>();
    const config = app.get(ConfigService);
    app.setGlobalPrefix(config.get<string>("app.apiPrefix", "api"));
    app.useStaticAssets(join(process.cwd(), "uploads"), {
      prefix: "/uploads",
    });
    app.useGlobalFilters(new HttpExceptionFilter());
    app.useGlobalInterceptors(new ResponseInterceptor());
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();

    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    await app.close();
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

  it("runs register-bind-wish-respond-confirm-fulfill-dish-checkin-feed flow", async () => {
    const unique = Date.now();
    const inviter = await post<{ token: string; user: { id: string } }>(
      "/api/auth/register",
      {
        email: `e2e-${unique}-a@example.com`,
        password: "secret123",
        nickname: "E2E A",
      },
    );
    const invitee = await post<{ token: string; user: { id: string } }>(
      "/api/auth/register",
      {
        email: `e2e-${unique}-b@example.com`,
        password: "secret123",
        nickname: "E2E B",
      },
    );

    const invite = await post<{ id: string; code: string }>(
      "/api/couples/generate-code",
      undefined,
      inviter.token,
    );
    const application = await post<{ id: string; inviteeId: string }>(
      "/api/couples/apply-by-code",
      { code: invite.code },
      invitee.token,
    );
    expect(application.inviteeId).toBe(invitee.user.id);

    const binding = await post<{ status: string; partner: { id: string } }>(
      `/api/couples/accept/${application.id}`,
      undefined,
      inviter.token,
    );
    expect(binding.status).toBe("BOUND");
    expect(binding.partner.id).toBe(invitee.user.id);

    const wish = await post<{
      id: string;
      status: string;
      currentResponse: { id: string } | null;
    }>(
      "/api/wishes",
      {
        title: "番茄牛腩",
        desiredTime: "WEEKEND",
        intensity: "WEEKEND_PLAN",
        helperTasks: ["买菜", "洗碗"],
      },
      inviter.token,
    );
    expect(wish.status).toBe("IN_POOL");

    const responded = await post<{
      status: string;
      currentResponse: { id: string };
    }>(
      `/api/wish-responses/wishes/${wish.id}`,
      {
        responseType: "LIGHT_VERSION",
        proposedTitle: "番茄鸡蛋面",
        reasonTags: ["今天有点累"],
      },
      invitee.token,
    );
    expect(responded.status).toBe("PENDING_CONFIRMATION");

    const confirmed = await patch<{ status: string }>(
      `/api/wish-responses/${responded.currentResponse.id}/confirm`,
      inviter.token,
    );
    expect(confirmed.status).toBe("CLAIMED");

    const uploaded = await request(app.getHttpServer())
      .post("/api/upload/dish-image")
      .set(authHeader(invitee.token))
      .attach("file", Buffer.from([0xff, 0xd8, 0xff, 0xd9]), {
        filename: "dish.jpg",
        contentType: "image/jpeg",
      })
      .expect(201)
      .then((response) => unwrap<{ url: string }>(response.body));
    expect(uploaded.url).toMatch(/^\/uploads\/dishes\/.+\.jpg$/);

    const avatar = await request(app.getHttpServer())
      .post("/api/upload/avatar")
      .set(authHeader(inviter.token))
      .attach("file", Buffer.from([0xff, 0xd8, 0xff, 0xd9]), {
        filename: "avatar.jpg",
        contentType: "image/jpeg",
      })
      .expect(201)
      .then((response) => unwrap<{ url: string }>(response.body));
    expect(avatar.url).toMatch(/^\/uploads\/avatars\/.+\.jpg$/);

    const updatedMe = await request(app.getHttpServer())
      .patch("/api/users/me")
      .set(authHeader(inviter.token))
      .send({ nickname: "E2E A", avatarUrl: avatar.url, gender: "MALE" })
      .expect(200)
      .then((response) =>
        unwrap<{ avatarUrl: string | null; gender: string }>(response.body),
      );
    expect(updatedMe.avatarUrl).toBe(avatar.url);
    expect(updatedMe.gender).toBe("MALE");

    await request(app.getHttpServer())
      .post("/api/upload/dish-image")
      .set(authHeader(invitee.token))
      .attach("file", Buffer.from("not an image"), {
        filename: "dish.txt",
        contentType: "text/plain",
      })
      .expect(400);

    await request(app.getHttpServer())
      .post("/api/upload/dish-image")
      .set(authHeader(invitee.token))
      .attach("file", Buffer.alloc(5 * 1024 * 1024 + 1), {
        filename: "large.jpg",
        contentType: "image/jpeg",
      })
      .expect(413);

    const fulfilled = await post<{
      wish: { status: string };
      fulfillment: { actualDishName: string };
    }>(
      `/api/wish-fulfillments/wishes/${wish.id}`,
      {
        actualDishName: "番茄鸡蛋面",
        helperTasksDone: ["洗碗"],
        feedbackTags: ["今天很好吃", "可以进常吃"],
        addToDishes: true,
        imageUrl: uploaded.url,
      },
      invitee.token,
    );
    expect(fulfilled.wish.status).toBe("FULFILLED");
    expect(fulfilled.fulfillment.actualDishName).toBe("番茄鸡蛋面");

    const dishes = await get<
      Array<{ id: string; name: string; imageUrl: string | null }>
    >("/api/dishes?isFavorite=true", inviter.token);
    expect(dishes.map((dish) => dish.name)).toContain("番茄鸡蛋面");
    expect(dishes.find((dish) => dish.name === "番茄鸡蛋面")?.imageUrl).toBe(
      uploaded.url,
    );

    const checkin = await post<{
      alreadyCheckedIn: boolean;
      points: { balance: number };
      status: { checkedInToday: boolean };
    }>("/api/checkins", undefined, inviter.token);
    expect(checkin.alreadyCheckedIn).toBe(false);
    expect(checkin.status.checkedInToday).toBe(true);
    expect(checkin.points.balance).toBeGreaterThanOrEqual(10);

    const fed = await post<{
      spirit: { level: number; exp: number };
      points: { balance: number };
    }>("/api/spirit/feed", { feedType: "NORMAL" }, inviter.token);
    expect(fed.spirit.exp).toBe(10);
    expect(fed.points.balance).toBe(checkin.points.balance - 10);

    const transactions = await get<Array<{ reason: string }>>(
      "/api/points/transactions",
      inviter.token,
    );
    expect(transactions.map((item) => item.reason)).toContain("FEED_SPIRIT");
  });

  async function post<T>(path: string, body?: unknown, token?: string) {
    const response = await request(app.getHttpServer())
      .post(path)
      .set(authHeader(token))
      .send(body ?? {})
      .expect(201);
    return unwrap<T>(response.body);
  }

  async function patch<T>(path: string, token?: string) {
    const response = await request(app.getHttpServer())
      .patch(path)
      .set(authHeader(token))
      .expect(200);
    return unwrap<T>(response.body);
  }

  async function get<T>(path: string, token: string) {
    const response = await request(app.getHttpServer())
      .get(path)
      .set(authHeader(token))
      .expect(200);
    return unwrap<T>(response.body);
  }

  function authHeader(token?: string) {
    return token ? { Authorization: `Bearer ${token}` } : {};
  }

  function unwrap<T>(body: ApiBody<T>) {
    expect(body.code).toBe(0);
    return body.data;
  }
});
