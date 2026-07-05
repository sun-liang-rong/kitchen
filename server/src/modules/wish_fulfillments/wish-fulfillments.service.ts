import { Injectable } from '@nestjs/common';
import { SharedDataService } from '../shared_data/shared-data.service';
import { CreateWishFulfillmentDto } from './dto/create-wish-fulfillment.dto';

@Injectable()
export class WishFulfillmentsService {
  constructor(private readonly data: SharedDataService) {}

  findAll(userId: string) {
    return this.data.listFulfillmentsForUser(userId);
  }

  create(userId: string, wishId: string, dto: CreateWishFulfillmentDto) {
    return this.data.fulfillWishForUser(userId, wishId, dto);
  }
}
