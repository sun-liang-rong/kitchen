import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  CoupleStatus,
  DesiredTime,
  DishDifficulty,
  KitchenStatusValue,
  NotificationType,
  SubstituteOption,
  WishIntensity,
  WishResponseType as PrismaWishResponseType,
  WishStatus as PrismaWishStatus,
  WishType,
} from "@prisma/client";
import { PrismaService } from "../../prisma/prisma.service";

export type WishStatus =
  | "IN_POOL"
  | "PENDING_CONFIRMATION"
  | "CLAIMED"
  | "DEFERRED"
  | "TOGETHER"
  | "SHELVED"
  | "FULFILLED";

export type WishResponseType =
  | "FULFILL_TONIGHT"
  | "LIGHT_VERSION"
  | "ALTERNATIVE"
  | "DEFER"
  | "TOGETHER"
  | "SHELVE";

@Injectable()
export class MvpDataService {
  readonly coupleId = "demo-couple";
  readonly users = [
    { id: "me", nickname: "我", role: "me" as const },
    { id: "partner", nickname: "她", role: "partner" as const },
  ];

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.ensureSeed();
  }

  async listWishes(status?: WishStatus, creatorId?: string) {
    await this.ensureSeed();
    return this.prisma.wish.findMany({
      where: {
        coupleId: this.coupleId,
        ...(status ? { status: this.toWishStatus(status) } : {}),
        ...(creatorId ? { creatorId } : {}),
      },
      orderBy: { createdAt: "desc" },
      include: this.wishInclude(),
    });
  }

  async listWishesForUser(
    userId: string,
    status?: WishStatus,
    creatorScope?: "me" | "partner",
  ) {
    const couple = await this.getActiveCoupleForUser(userId);
    const partnerId =
      couple.userAId === userId ? couple.userBId : couple.userAId;
    const creatorId =
      creatorScope === "me"
        ? userId
        : creatorScope === "partner"
          ? partnerId
          : undefined;
    return this.prisma.wish.findMany({
      where: {
        coupleId: couple.id,
        ...(status ? { status: this.toWishStatus(status) } : {}),
        ...(creatorId ? { creatorId } : {}),
      },
      orderBy: { createdAt: "desc" },
      include: this.wishInclude(),
    });
  }

  async getWish(id: string) {
    const wish = await this.prisma.wish.findUnique({
      where: { id },
      include: this.wishInclude(),
    });
    if (!wish) {
      throw new NotFoundException("愿望不存在");
    }
    return wish;
  }

  async getWishForUser(userId: string, id: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    const wish = await this.prisma.wish.findFirst({
      where: { id, coupleId: couple.id },
      include: this.wishInclude(),
    });
    if (!wish) {
      throw new NotFoundException("愿望不存在");
    }
    return wish;
  }

  async deleteWish(id: string) {
    const wish = await this.findWish(id);
    if (wish.status === PrismaWishStatus.FULFILLED) {
      throw new BadRequestException("已兑现的愿望会保留在历史里，不能删除");
    }
    await this.deleteWishRecords(id);
    return { deleted: true, id };
  }

  async deleteWishForUser(userId: string, id: string) {
    const wish = await this.assertWishBelongsToUserCouple(userId, id);
    if (wish.creatorId !== userId) {
      throw new ForbiddenException("只能删除自己许下的愿望");
    }
    if (wish.status === PrismaWishStatus.FULFILLED) {
      throw new BadRequestException("已兑现的愿望会保留在历史里，不能删除");
    }
    await this.deleteWishRecords(id);
    return { deleted: true, id };
  }

  async createWish(input: {
    creatorId?: string;
    title: string;
    wishType?: string;
    feelingTags?: string[];
    desiredTime?: string;
    intensity?: string;
    substituteOption?: string;
    helperTasks?: string[];
  }) {
    await this.ensureSeed();
    if (!input.title?.trim()) {
      throw new BadRequestException("愿望标题不能为空");
    }

    return this.prisma.wish.create({
      data: {
        coupleId: this.coupleId,
        creatorId: input.creatorId ?? "me",
        title: input.title.trim(),
        wishType: this.toWishType(input.wishType),
        feelingTags: input.feelingTags ?? [],
        desiredTime: this.toDesiredTime(input.desiredTime),
        intensity: this.toWishIntensity(input.intensity),
        substituteOption: this.toSubstituteOption(input.substituteOption),
        helperTasks: input.helperTasks ?? [],
        status: PrismaWishStatus.IN_POOL,
      },
      include: this.wishInclude(),
    });
  }

  async createWishForUser(
    userId: string,
    input: {
      title: string;
      wishType?: string;
      feelingTags?: string[];
      desiredTime?: string;
      intensity?: string;
      substituteOption?: string;
      helperTasks?: string[];
    },
  ) {
    const couple = await this.getActiveCoupleForUser(userId);
    if (!input.title?.trim()) {
      throw new BadRequestException("愿望标题不能为空");
    }

    const wish = await this.prisma.wish.create({
      data: {
        coupleId: couple.id,
        creatorId: userId,
        title: input.title.trim(),
        wishType: this.toWishType(input.wishType),
        feelingTags: input.feelingTags ?? [],
        desiredTime: this.toDesiredTime(input.desiredTime),
        intensity: this.toWishIntensity(input.intensity),
        substituteOption: this.toSubstituteOption(input.substituteOption),
        helperTasks: input.helperTasks ?? [],
        status: PrismaWishStatus.IN_POOL,
      },
      include: this.wishInclude(),
    });
    await this.createNotificationForPartner(userId, couple.id, {
      type: NotificationType.WISH_CREATED,
      title: "有新的吃饭愿望",
      content: `${this.userName(couple, userId)}许愿：${wish.title}`,
      relatedId: wish.id,
    });
    return wish;
  }

  async respondToWish(
    wishId: string,
    input: {
      responderId?: string;
      responseType: WishResponseType;
      proposedTitle?: string;
      proposedTime?: string;
      reasonTags?: string[];
      reasonText?: string;
    },
  ) {
    const wish = await this.findWish(wishId);
    if (wish.status === PrismaWishStatus.FULFILLED) {
      throw new BadRequestException("已兑现的愿望不能再次回应");
    }
    this.assertCanRespond(wish.status);

    const responseType = this.toWishResponseType(input.responseType);
    const response = await this.prisma.wishResponse.create({
      data: {
        wishId,
        responderId: input.responderId ?? "partner",
        responseType,
        proposedTitle: input.proposedTitle,
        proposedTime: this.toDesiredTime(input.proposedTime),
        reasonTags: input.reasonTags ?? [],
        reasonText: input.reasonText,
      },
    });

    const updatedWish = await this.prisma.wish.update({
      where: { id: wishId },
      data: {
        currentResponseId: response.id,
        status: this.statusForResponse(responseType),
      },
      include: this.wishInclude(),
    });
    await this.prisma.notification.create({
      data: {
        userId: wish.creatorId,
        type: NotificationType.WISH_RESPONDED,
        title: "愿望有回应了",
        content: `${this.responseTypeText(responseType)}：${wish.title}`,
        relatedId: wish.id,
      },
    });
    return updatedWish;
  }

  async respondToWishForUser(
    userId: string,
    wishId: string,
    input: {
      responseType: WishResponseType;
      proposedTitle?: string;
      proposedTime?: string;
      reasonTags?: string[];
      reasonText?: string;
    },
  ) {
    const wish = await this.getWishForUser(userId, wishId);
    if (wish.creatorId === userId) {
      throw new BadRequestException("不能回应自己许下的愿望");
    }
    if (wish.status === PrismaWishStatus.FULFILLED) {
      throw new BadRequestException("已兑现的愿望不能再次回应");
    }
    this.assertCanRespond(wish.status);

    const responseType = this.toWishResponseType(input.responseType);
    const response = await this.prisma.wishResponse.create({
      data: {
        wishId,
        responderId: userId,
        responseType,
        proposedTitle: input.proposedTitle,
        proposedTime: this.toDesiredTime(input.proposedTime),
        reasonTags: input.reasonTags ?? [],
        reasonText: input.reasonText,
      },
    });

    return this.prisma.wish.update({
      where: { id: wishId },
      data: {
        currentResponseId: response.id,
        status: this.statusForResponse(responseType),
      },
      include: this.wishInclude(),
    });
  }

  async confirmResponse(responseId: string) {
    const response = await this.prisma.wishResponse.findUnique({
      where: { id: responseId },
    });
    if (!response) {
      throw new NotFoundException("回应不存在");
    }
    const wish = await this.findWish(response.wishId);
    this.assertCurrentPendingResponse(wish, response.id);

    await this.prisma.wishResponse.update({
      where: { id: responseId },
      data: { confirmedAt: new Date() },
    });

    return this.prisma.wish.update({
      where: { id: response.wishId },
      data: { status: this.confirmedStatusForResponse(response.responseType) },
      include: this.wishInclude(),
    });
  }

  async reopenResponse(responseId: string) {
    const response = await this.prisma.wishResponse.findUnique({
      where: { id: responseId },
    });
    if (!response) {
      throw new NotFoundException("回应不存在");
    }
    const wish = await this.findWish(response.wishId);
    this.assertCurrentPendingResponse(wish, response.id);

    return this.prisma.wish.update({
      where: { id: response.wishId },
      data: {
        currentResponseId: null,
        status: PrismaWishStatus.IN_POOL,
      },
      include: this.wishInclude(),
    });
  }

  async confirmResponseForUser(userId: string, responseId: string) {
    const response = await this.prisma.wishResponse.findUnique({
      where: { id: responseId },
      include: { wish: true },
    });
    if (!response) {
      throw new NotFoundException("回应不存在");
    }
    await this.assertWishBelongsToUserCouple(userId, response.wishId);
    if (response.wish.creatorId !== userId) {
      throw new ForbiddenException("只有许愿人可以确认回应");
    }
    this.assertCurrentPendingResponse(response.wish, response.id);

    await this.prisma.wishResponse.update({
      where: { id: responseId },
      data: { confirmedAt: new Date() },
    });

    const updatedWish = await this.prisma.wish.update({
      where: { id: response.wishId },
      data: { status: this.confirmedStatusForResponse(response.responseType) },
      include: this.wishInclude(),
    });
    await this.prisma.notification.create({
      data: {
        userId: response.responderId,
        type: NotificationType.WISH_CLAIMED,
        title: "对方确认了安排",
        content: `愿望已确认：${response.wish.title}`,
        relatedId: response.wishId,
      },
    });
    return updatedWish;
  }

  async reopenResponseForUser(userId: string, responseId: string) {
    const response = await this.prisma.wishResponse.findUnique({
      where: { id: responseId },
      include: { wish: true },
    });
    if (!response) {
      throw new NotFoundException("回应不存在");
    }
    await this.assertWishBelongsToUserCouple(userId, response.wishId);
    if (response.wish.creatorId !== userId) {
      throw new ForbiddenException("只有许愿人可以让愿望继续商量");
    }
    this.assertCurrentPendingResponse(response.wish, response.id);

    const updatedWish = await this.prisma.wish.update({
      where: { id: response.wishId },
      data: {
        currentResponseId: null,
        status: PrismaWishStatus.IN_POOL,
      },
      include: this.wishInclude(),
    });
    await this.prisma.notification.create({
      data: {
        userId: response.responderId,
        type: NotificationType.WISH_RESPONDED,
        title: "对方想再改一下",
        content: `愿望回到池中继续商量：${response.wish.title}`,
        relatedId: response.wishId,
      },
    });
    return updatedWish;
  }

  async fulfillWish(
    wishId: string,
    input: {
      fulfillerId?: string;
      actualDishName: string;
      helperTasksDone?: string[];
      feedbackTags?: string[];
      note?: string;
      addToDishes?: boolean;
    },
  ) {
    const wish = await this.findWish(wishId);
    if (!input.actualDishName?.trim()) {
      throw new BadRequestException("实际吃了什么不能为空");
    }
    this.assertCanFulfill(wish.status);

    const fulfillment = await this.prisma.wishFulfillment.upsert({
      where: { wishId },
      create: {
        wishId,
        fulfillerId: input.fulfillerId ?? "partner",
        actualDishName: input.actualDishName.trim(),
        helperTasksDone: input.helperTasksDone ?? [],
        feedbackTags: input.feedbackTags ?? [],
        note: input.note,
        addToDishes: input.addToDishes ?? false,
      },
      update: {
        fulfillerId: input.fulfillerId ?? "partner",
        actualDishName: input.actualDishName.trim(),
        helperTasksDone: input.helperTasksDone ?? [],
        feedbackTags: input.feedbackTags ?? [],
        note: input.note,
        addToDishes: input.addToDishes ?? false,
      },
    });

    if (fulfillment.addToDishes) {
      await this.createDish({
        name: fulfillment.actualDishName,
        cookOwner: fulfillment.fulfillerId,
        suitableTimeTags: [wish.desiredTime ?? DesiredTime.SOMEDAY],
        tasteTags: fulfillment.feedbackTags,
        isFavorite: true,
        sourceWishId: wish.id,
        lastFeedback: fulfillment.feedbackTags.join("、"),
      });
    }

    const updatedWish = await this.prisma.wish.update({
      where: { id: wishId },
      data: { status: PrismaWishStatus.FULFILLED },
      include: this.wishInclude(),
    });
    return { wish: updatedWish, fulfillment };
  }

  async fulfillWishForUser(
    userId: string,
    wishId: string,
    input: {
      actualDishName: string;
      helperTasksDone?: string[];
      feedbackTags?: string[];
      note?: string;
      addToDishes?: boolean;
    },
  ) {
    const couple = await this.getActiveCoupleForUser(userId);
    const wish = await this.prisma.wish.findFirst({
      where: { id: wishId, coupleId: couple.id },
    });
    if (!wish) {
      throw new NotFoundException("愿望不存在");
    }
    if (!input.actualDishName?.trim()) {
      throw new BadRequestException("实际吃了什么不能为空");
    }
    this.assertCanFulfill(wish.status);

    const fulfillment = await this.prisma.wishFulfillment.upsert({
      where: { wishId },
      create: {
        wishId,
        fulfillerId: userId,
        actualDishName: input.actualDishName.trim(),
        helperTasksDone: input.helperTasksDone ?? [],
        feedbackTags: input.feedbackTags ?? [],
        note: input.note,
        addToDishes: input.addToDishes ?? false,
      },
      update: {
        fulfillerId: userId,
        actualDishName: input.actualDishName.trim(),
        helperTasksDone: input.helperTasksDone ?? [],
        feedbackTags: input.feedbackTags ?? [],
        note: input.note,
        addToDishes: input.addToDishes ?? false,
      },
    });

    if (fulfillment.addToDishes) {
      await this.createDishForUser(userId, {
        name: fulfillment.actualDishName,
        cookOwner: fulfillment.fulfillerId,
        suitableTimeTags: [wish.desiredTime ?? DesiredTime.SOMEDAY],
        tasteTags: fulfillment.feedbackTags,
        isFavorite: true,
        sourceWishId: wish.id,
        lastFeedback: fulfillment.feedbackTags.join("、"),
      });
    }

    const updatedWish = await this.prisma.wish.update({
      where: { id: wishId },
      data: { status: PrismaWishStatus.FULFILLED },
      include: this.wishInclude(),
    });
    const notifyUserId =
      wish.creatorId === userId
        ? this.partnerIdForWishUser(couple, userId)
        : wish.creatorId;
    await this.prisma.notification.create({
      data: {
        userId: notifyUserId,
        type: NotificationType.WISH_FULFILLED,
        title: "愿望兑现啦",
        content: `今天吃上了：${fulfillment.actualDishName}`,
        relatedId: wish.id,
      },
    });

    return { wish: updatedWish, fulfillment };
  }

  async listFulfillments() {
    await this.ensureSeed();
    return this.prisma.wishFulfillment.findMany({
      orderBy: { createdAt: "desc" },
      include: { wish: true },
    });
  }

  async listFulfillmentsForUser(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    return this.prisma.wishFulfillment.findMany({
      where: { wish: { coupleId: couple.id } },
      orderBy: { createdAt: "desc" },
      include: { wish: true },
    });
  }

  async listDishes(filter?: {
    suitableTimeTag?: string;
    cookOwner?: string;
    q?: string;
    difficulty?: string;
    isFavorite?: boolean;
  }) {
    await this.ensureSeed();
    const q = filter?.q?.trim();
    return this.prisma.dish.findMany({
      where: {
        coupleId: this.coupleId,
        ...(filter?.suitableTimeTag
          ? { suitableTimeTags: { has: filter.suitableTimeTag } }
          : {}),
        ...(filter?.cookOwner ? { cookOwner: filter.cookOwner } : {}),
        ...(filter?.difficulty
          ? { difficulty: this.toDishDifficulty(filter.difficulty) }
          : {}),
        ...(typeof filter?.isFavorite === "boolean"
          ? { isFavorite: filter.isFavorite }
          : {}),
        ...(q
          ? {
              OR: [
                { name: { contains: q, mode: "insensitive" as const } },
                { lastFeedback: { contains: q, mode: "insensitive" as const } },
                { tasteTags: { has: q } },
                { suitableTimeTags: { has: q } },
              ],
            }
          : {}),
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async listDishesForUser(
    userId: string,
    filter?: {
      suitableTimeTag?: string;
      cookOwner?: string;
      q?: string;
      difficulty?: string;
      isFavorite?: boolean;
    },
  ) {
    const couple = await this.getActiveCoupleForUser(userId);
    const q = filter?.q?.trim();
    return this.prisma.dish.findMany({
      where: {
        coupleId: couple.id,
        ...(filter?.suitableTimeTag
          ? { suitableTimeTags: { has: filter.suitableTimeTag } }
          : {}),
        ...(filter?.cookOwner ? { cookOwner: filter.cookOwner } : {}),
        ...(filter?.difficulty
          ? { difficulty: this.toDishDifficulty(filter.difficulty) }
          : {}),
        ...(typeof filter?.isFavorite === "boolean"
          ? { isFavorite: filter.isFavorite }
          : {}),
        ...(q
          ? {
              OR: [
                { name: { contains: q, mode: "insensitive" as const } },
                { lastFeedback: { contains: q, mode: "insensitive" as const } },
                { tasteTags: { has: q } },
                { suitableTimeTags: { has: q } },
              ],
            }
          : {}),
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async createDish(input: {
    name: string;
    cookOwner?: string;
    suitableTimeTags?: string[];
    difficulty?: string;
    tasteTags?: string[];
    isFavorite?: boolean;
    sourceWishId?: string;
    lastFeedback?: string;
  }) {
    await this.ensureSeed();
    if (!input.name?.trim()) {
      throw new BadRequestException("菜名不能为空");
    }

    const existing = await this.prisma.dish.findFirst({
      where: { coupleId: this.coupleId, name: input.name.trim() },
    });

    const data = {
      cookOwner: input.cookOwner,
      suitableTimeTags: input.suitableTimeTags ?? [],
      difficulty: this.toDishDifficulty(input.difficulty),
      tasteTags: input.tasteTags ?? [],
      isFavorite: input.isFavorite ?? false,
      sourceWishId: input.sourceWishId,
      lastFeedback: input.lastFeedback,
    };

    if (existing) {
      return this.prisma.dish.update({
        where: { id: existing.id },
        data,
      });
    }

    return this.prisma.dish.create({
      data: {
        coupleId: this.coupleId,
        name: input.name.trim(),
        ...data,
      },
    });
  }

  async createDishForUser(
    userId: string,
    input: {
      name: string;
      cookOwner?: string;
      suitableTimeTags?: string[];
      difficulty?: string;
      tasteTags?: string[];
      isFavorite?: boolean;
      sourceWishId?: string;
      lastFeedback?: string;
    },
  ) {
    const couple = await this.getActiveCoupleForUser(userId);
    if (!input.name?.trim()) {
      throw new BadRequestException("菜名不能为空");
    }

    const existing = await this.prisma.dish.findFirst({
      where: { coupleId: couple.id, name: input.name.trim() },
    });
    const data = {
      cookOwner: input.cookOwner ?? userId,
      suitableTimeTags: input.suitableTimeTags ?? [],
      difficulty: this.toDishDifficulty(input.difficulty),
      tasteTags: input.tasteTags ?? [],
      isFavorite: input.isFavorite ?? false,
      sourceWishId: input.sourceWishId,
      lastFeedback: input.lastFeedback,
    };

    if (existing) {
      return this.prisma.dish.update({ where: { id: existing.id }, data });
    }

    return this.prisma.dish.create({
      data: {
        coupleId: couple.id,
        name: input.name.trim(),
        ...data,
      },
    });
  }

  async updateDish(id: string, input: { [key: string]: unknown }) {
    const dish = await this.prisma.dish.findUnique({ where: { id } });
    if (!dish) {
      throw new NotFoundException("菜不存在");
    }

    return this.prisma.dish.update({
      where: { id },
      data: {
        name: typeof input.name === "string" ? input.name : undefined,
        cookOwner:
          typeof input.cookOwner === "string" ? input.cookOwner : undefined,
        suitableTimeTags: Array.isArray(input.suitableTimeTags)
          ? input.suitableTimeTags.filter(
              (item): item is string => typeof item === "string",
            )
          : undefined,
        difficulty:
          typeof input.difficulty === "string"
            ? this.toDishDifficulty(input.difficulty)
            : undefined,
        tasteTags: Array.isArray(input.tasteTags)
          ? input.tasteTags.filter(
              (item): item is string => typeof item === "string",
            )
          : undefined,
        isFavorite:
          typeof input.isFavorite === "boolean" ? input.isFavorite : undefined,
        lastFeedback:
          typeof input.lastFeedback === "string"
            ? input.lastFeedback
            : undefined,
      },
    });
  }

  async updateDishForUser(
    userId: string,
    id: string,
    input: { [key: string]: unknown },
  ) {
    const couple = await this.getActiveCoupleForUser(userId);
    const dish = await this.prisma.dish.findFirst({
      where: { id, coupleId: couple.id },
    });
    if (!dish) {
      throw new NotFoundException("菜不存在");
    }

    return this.prisma.dish.update({
      where: { id },
      data: {
        name: typeof input.name === "string" ? input.name : undefined,
        cookOwner:
          typeof input.cookOwner === "string" ? input.cookOwner : undefined,
        suitableTimeTags: Array.isArray(input.suitableTimeTags)
          ? input.suitableTimeTags.filter(
              (item): item is string => typeof item === "string",
            )
          : undefined,
        difficulty:
          typeof input.difficulty === "string"
            ? this.toDishDifficulty(input.difficulty)
            : undefined,
        tasteTags: Array.isArray(input.tasteTags)
          ? input.tasteTags.filter(
              (item): item is string => typeof item === "string",
            )
          : undefined,
        isFavorite:
          typeof input.isFavorite === "boolean" ? input.isFavorite : undefined,
        lastFeedback:
          typeof input.lastFeedback === "string"
            ? input.lastFeedback
            : undefined,
      },
    });
  }

  async getKitchenStatuses() {
    await this.ensureSeed();
    const statuses = await this.prisma.kitchenStatus.findMany({
      where: { userId: { in: this.users.map((user) => user.id) } },
      orderBy: { updatedAt: "desc" },
    });

    return this.users.map((user) => ({
      user,
      status: statuses.find((status) => status.userId === user.id),
    }));
  }

  async getKitchenStatusesForUser(userId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    const users = [couple.userA, couple.userB];
    const statuses = await this.prisma.kitchenStatus.findMany({
      where: { userId: { in: users.map((user) => user.id) } },
      orderBy: { updatedAt: "desc" },
    });

    return users.map((user) => ({
      user,
      status: statuses.find((status) => status.userId === user.id),
    }));
  }

  async setKitchenStatus(userId: string, status: string, note?: string) {
    await this.ensureSeed();
    if (!this.users.some((user) => user.id === userId)) {
      throw new NotFoundException("用户不存在");
    }

    return this.prisma.kitchenStatus.upsert({
      where: { userId_date: { userId, date: this.today() } },
      create: {
        userId,
        status: this.toKitchenStatus(status),
        note,
        date: this.today(),
      },
      update: {
        status: this.toKitchenStatus(status),
        note,
      },
    });
  }

  async setKitchenStatusForUser(userId: string, status: string, note?: string) {
    await this.getActiveCoupleForUser(userId);
    return this.prisma.kitchenStatus.upsert({
      where: { userId_date: { userId, date: this.today() } },
      create: {
        userId,
        status: this.toKitchenStatus(status),
        note,
        date: this.today(),
      },
      update: {
        status: this.toKitchenStatus(status),
        note,
      },
    });
  }

  async resetDemoData() {
    await this.prisma.notification.deleteMany({});
    await this.prisma.dish.updateMany({ data: { sourceWishId: null } });
    await this.prisma.dish.deleteMany({});
    await this.prisma.wish.updateMany({ data: { currentResponseId: null } });
    await this.prisma.wishFulfillment.deleteMany({});
    await this.prisma.wishResponse.deleteMany({});
    await this.prisma.wish.deleteMany({});
    await this.prisma.kitchenStatus.deleteMany({});
    await this.prisma.coupleInvite.deleteMany({});
    await this.prisma.couple.deleteMany({});
    await this.prisma.user.deleteMany({});
    await this.ensureSeed();
  }

  private async ensureSeed() {
    const existingCouple = await this.prisma.couple.findUnique({
      where: { id: this.coupleId },
    });
    if (existingCouple) {
      return;
    }

    await this.prisma.user.createMany({
      data: [
        { id: "me", nickname: "我" },
        { id: "partner", nickname: "她" },
      ],
      skipDuplicates: true,
    });

    await this.prisma.couple.upsert({
      where: { id: this.coupleId },
      create: {
        id: this.coupleId,
        userAId: "me",
        userBId: "partner",
      },
      update: {
        userAId: "me",
        userBId: "partner",
        status: "ACTIVE",
      },
    });

    await this.setKitchenStatus("me", "NORMAL", "今天正常做饭");
    await this.setKitchenStatus("partner", "TIRED", "她今天有点累，适合简单点");

    await this.createWish({
      creatorId: "partner",
      title: "可乐鸡翅",
      wishType: "DISH",
      desiredTime: "TONIGHT",
      intensity: "VERY_TODAY",
      substituteOption: "LIGHT_VERSION_OK",
      helperTasks: ["洗菜", "饭后收桌"],
    });
    await this.createWish({
      creatorId: "me",
      title: "今晚想喝汤",
      wishType: "FEELING",
      feelingTags: ["有汤", "热乎一点"],
      desiredTime: "THIS_WEEK",
      intensity: "THIS_WEEK",
      substituteOption: "WHAT_WE_HAVE_OK",
      helperTasks: ["洗碗"],
    });

    await this.createDish({
      name: "番茄鸡蛋面",
      cookOwner: "me",
      suitableTimeTags: ["TONIGHT", "SIMPLE_ONLY"],
      difficulty: "EASY",
      tasteTags: ["热乎", "快手"],
      isFavorite: true,
    });
  }

  private async findWish(id: string) {
    const wish = await this.prisma.wish.findUnique({ where: { id } });
    if (!wish) {
      throw new NotFoundException("愿望不存在");
    }
    return wish;
  }

  private async deleteWishRecords(id: string) {
    await this.prisma.notification.deleteMany({ where: { relatedId: id } });
    await this.prisma.dish.updateMany({
      where: { sourceWishId: id },
      data: { sourceWishId: null },
    });
    await this.prisma.wish.update({
      where: { id },
      data: { currentResponseId: null },
    });
    await this.prisma.wishResponse.deleteMany({ where: { wishId: id } });
    await this.prisma.wish.delete({ where: { id } });
  }

  private async getActiveCoupleForUser(userId: string) {
    const couple = await this.prisma.couple.findFirst({
      where: {
        status: CoupleStatus.ACTIVE,
        OR: [{ userAId: userId }, { userBId: userId }],
      },
      include: { userA: true, userB: true },
    });
    if (!couple) {
      throw new BadRequestException("请先完成双人绑定");
    }
    return couple;
  }

  private async assertWishBelongsToUserCouple(userId: string, wishId: string) {
    const couple = await this.getActiveCoupleForUser(userId);
    const wish = await this.prisma.wish.findFirst({
      where: { id: wishId, coupleId: couple.id },
    });
    if (!wish) {
      throw new NotFoundException("愿望不存在");
    }
    return wish;
  }

  private async createNotificationForPartner(
    userId: string,
    coupleId: string,
    input: {
      type: NotificationType;
      title: string;
      content: string;
      relatedId?: string;
    },
  ) {
    const couple = await this.prisma.couple.findUnique({
      where: { id: coupleId },
    });
    if (!couple) {
      return;
    }
    await this.prisma.notification.create({
      data: {
        userId: this.partnerIdForWishUser(couple, userId),
        type: input.type,
        title: input.title,
        content: input.content,
        relatedId: input.relatedId,
      },
    });
  }

  private partnerIdForWishUser(
    couple: { userAId: string; userBId: string },
    userId: string,
  ) {
    return couple.userAId === userId ? couple.userBId : couple.userAId;
  }

  private userName(
    couple: {
      userA: { nickname: string };
      userB: { nickname: string };
      userAId: string;
    },
    userId: string,
  ) {
    return couple.userAId === userId
      ? couple.userA.nickname
      : couple.userB.nickname;
  }

  private responseTypeText(responseType: PrismaWishResponseType) {
    if (responseType === PrismaWishResponseType.LIGHT_VERSION) {
      return "做轻松版";
    }
    if (responseType === PrismaWishResponseType.ALTERNATIVE) {
      return "换个版本";
    }
    if (responseType === PrismaWishResponseType.DEFER) {
      return "改天实现";
    }
    if (responseType === PrismaWishResponseType.TOGETHER) {
      return "一起完成";
    }
    if (responseType === PrismaWishResponseType.SHELVE) {
      return "先搁着";
    }
    return "今晚实现";
  }

  private wishInclude() {
    return {
      creator: true,
      currentResponse: true,
      responses: { orderBy: { createdAt: "asc" as const } },
      fulfillment: true,
    };
  }

  private today() {
    const date = new Date();
    date.setHours(0, 0, 0, 0);
    return date;
  }

  private statusForResponse(responseType: PrismaWishResponseType) {
    if (this.needsConfirmation(responseType)) {
      return PrismaWishStatus.PENDING_CONFIRMATION;
    }
    if (responseType === PrismaWishResponseType.SHELVE) {
      return PrismaWishStatus.SHELVED;
    }
    return PrismaWishStatus.CLAIMED;
  }

  private confirmedStatusForResponse(responseType: PrismaWishResponseType) {
    if (responseType === PrismaWishResponseType.DEFER) {
      return PrismaWishStatus.DEFERRED;
    }
    if (responseType === PrismaWishResponseType.TOGETHER) {
      return PrismaWishStatus.TOGETHER;
    }
    return PrismaWishStatus.CLAIMED;
  }

  private needsConfirmation(responseType: PrismaWishResponseType) {
    return (
      responseType === PrismaWishResponseType.LIGHT_VERSION ||
      responseType === PrismaWishResponseType.ALTERNATIVE ||
      responseType === PrismaWishResponseType.DEFER ||
      responseType === PrismaWishResponseType.TOGETHER
    );
  }

  private assertCanRespond(status: PrismaWishStatus) {
    if (
      status !== PrismaWishStatus.IN_POOL &&
      status !== PrismaWishStatus.SHELVED
    ) {
      throw new BadRequestException("只有池中或先搁着的愿望可以继续回应");
    }
  }

  private assertCurrentPendingResponse(
    wish: { status: PrismaWishStatus; currentResponseId: string | null },
    responseId: string,
  ) {
    if (wish.status !== PrismaWishStatus.PENDING_CONFIRMATION) {
      throw new BadRequestException("只有待确认的回应可以这样处理");
    }
    if (wish.currentResponseId !== responseId) {
      throw new BadRequestException("只能处理当前等待确认的回应");
    }
  }

  private assertCanFulfill(status: PrismaWishStatus) {
    if (
      status !== PrismaWishStatus.CLAIMED &&
      status !== PrismaWishStatus.DEFERRED &&
      status !== PrismaWishStatus.TOGETHER
    ) {
      throw new BadRequestException("只有已确认安排的愿望可以记录兑现");
    }
  }

  private toWishType(value?: string) {
    return value && value in WishType ? (value as WishType) : WishType.DISH;
  }

  private toDesiredTime(value?: string | DesiredTime | null) {
    return value && value in DesiredTime
      ? (value as DesiredTime)
      : DesiredTime.TONIGHT;
  }

  private toWishIntensity(value?: string) {
    return value && value in WishIntensity
      ? (value as WishIntensity)
      : WishIntensity.TODAY;
  }

  private toSubstituteOption(value?: string) {
    return value && value in SubstituteOption
      ? (value as SubstituteOption)
      : SubstituteOption.SIMILAR_OK;
  }

  private toWishStatus(value: WishStatus) {
    return value in PrismaWishStatus
      ? (value as PrismaWishStatus)
      : PrismaWishStatus.IN_POOL;
  }

  private toWishResponseType(value: WishResponseType) {
    return value in PrismaWishResponseType
      ? (value as PrismaWishResponseType)
      : PrismaWishResponseType.FULFILL_TONIGHT;
  }

  private toKitchenStatus(value: string) {
    return value in KitchenStatusValue
      ? (value as KitchenStatusValue)
      : KitchenStatusValue.NORMAL;
  }

  private toDishDifficulty(value?: string) {
    return value && value in DishDifficulty
      ? (value as DishDifficulty)
      : DishDifficulty.NORMAL;
  }
}
