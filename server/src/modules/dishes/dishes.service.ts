import { Injectable } from "@nestjs/common";
import { SharedDataService } from "../shared_data/shared-data.service";
import { UpsertDishDto } from "./dto/upsert-dish.dto";

@Injectable()
export class DishesService {
  constructor(private readonly data: SharedDataService) {}

  findAll(input: {
    suitableTimeTag?: string;
    cookOwner?: string;
    userId: string;
    q?: string;
    difficulty?: string;
    isFavorite?: boolean;
  }) {
    const { suitableTimeTag, cookOwner, userId, q, difficulty, isFavorite } =
      input;
    return this.data.listDishesForUser(userId, {
      suitableTimeTag,
      cookOwner,
      q,
      difficulty,
      isFavorite,
    });
  }

  create(userId: string, dto: UpsertDishDto) {
    return this.data.createDishForUser(userId, dto);
  }

  update(userId: string, id: string, dto: Partial<UpsertDishDto>) {
    return this.data.updateDishForUser(userId, id, dto);
  }

  remove(userId: string, id: string) {
    return this.data.deleteDishForUser(userId, id);
  }
}
