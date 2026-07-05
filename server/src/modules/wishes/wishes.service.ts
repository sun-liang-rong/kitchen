import { Injectable } from '@nestjs/common';
import { MvpDataService, WishStatus } from '../mvp_data/mvp-data.service';
import { CreateWishDto } from './dto/create-wish.dto';

@Injectable()
export class WishesService {
  constructor(private readonly data: MvpDataService) {}

  findAll(status?: WishStatus, userId?: string, creator?: 'me' | 'partner') {
    if (userId) {
      return this.data.listWishesForUser(userId, status, creator);
    }
    const demoCreatorId = creator === 'me' ? 'me' : creator === 'partner' ? 'partner' : undefined;
    return this.data.listWishes(status, demoCreatorId);
  }

  findOne(id: string, userId?: string) {
    return userId ? this.data.getWishForUser(userId, id) : this.data.getWish(id);
  }

  create(dto: CreateWishDto, userId?: string) {
    return userId ? this.data.createWishForUser(userId, dto) : this.data.createWish(dto);
  }

  remove(id: string, userId?: string) {
    return userId ? this.data.deleteWishForUser(userId, id) : this.data.deleteWish(id);
  }
}
