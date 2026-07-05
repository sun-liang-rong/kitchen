import { Injectable } from '@nestjs/common';
import { MvpDataService } from '../mvp_data/mvp-data.service';
import { CreateWishFulfillmentDto } from './dto/create-wish-fulfillment.dto';

@Injectable()
export class WishFulfillmentsService {
  constructor(private readonly data: MvpDataService) {}

  findAll(userId?: string) {
    return userId ? this.data.listFulfillmentsForUser(userId) : this.data.listFulfillments();
  }

  create(wishId: string, dto: CreateWishFulfillmentDto, userId?: string) {
    return userId ? this.data.fulfillWishForUser(userId, wishId, dto) : this.data.fulfillWish(wishId, dto);
  }
}
