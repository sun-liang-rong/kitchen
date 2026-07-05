import { Injectable } from '@nestjs/common';
import { MvpDataService } from '../mvp_data/mvp-data.service';
import { UpsertDishDto } from './dto/upsert-dish.dto';

@Injectable()
export class DishesService {
  constructor(private readonly data: MvpDataService) {}

  findAll(input: {
    suitableTimeTag?: string;
    cookOwner?: string;
    userId?: string;
    q?: string;
    difficulty?: string;
    isFavorite?: boolean;
  }) {
    const { suitableTimeTag, cookOwner, userId, q, difficulty, isFavorite } = input;
    return userId
      ? this.data.listDishesForUser(userId, { suitableTimeTag, cookOwner, q, difficulty, isFavorite })
      : this.data.listDishes({ suitableTimeTag, cookOwner, q, difficulty, isFavorite });
  }

  create(dto: UpsertDishDto, userId?: string) {
    return userId ? this.data.createDishForUser(userId, dto) : this.data.createDish(dto);
  }

  update(id: string, dto: Partial<UpsertDishDto>, userId?: string) {
    return userId ? this.data.updateDishForUser(userId, id, dto) : this.data.updateDish(id, dto);
  }
}
