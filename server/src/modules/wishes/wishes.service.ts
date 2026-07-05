import { Injectable } from '@nestjs/common';
import { SharedDataService, WishStatus } from '../shared_data/shared-data.service';
import { CreateWishDto } from './dto/create-wish.dto';

@Injectable()
export class WishesService {
  constructor(private readonly data: SharedDataService) {}

  findAll(userId: string, status?: WishStatus, creator?: 'me' | 'partner') {
    return this.data.listWishesForUser(userId, status, creator);
  }

  findOne(userId: string, id: string) {
    return this.data.getWishForUser(userId, id);
  }

  create(userId: string, dto: CreateWishDto) {
    return this.data.createWishForUser(userId, dto);
  }

  remove(userId: string, id: string) {
    return this.data.deleteWishForUser(userId, id);
  }
}
