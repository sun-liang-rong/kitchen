import { Injectable } from '@nestjs/common';
import { SharedDataService } from '../shared_data/shared-data.service';
import { CreateWishResponseDto } from './dto/create-wish-response.dto';

@Injectable()
export class WishResponsesService {
  constructor(private readonly data: SharedDataService) {}

  create(userId: string, wishId: string, dto: CreateWishResponseDto) {
    return this.data.respondToWishForUser(userId, wishId, dto);
  }

  confirm(userId: string, responseId: string) {
    return this.data.confirmResponseForUser(userId, responseId);
  }

  reopen(userId: string, responseId: string) {
    return this.data.reopenResponseForUser(userId, responseId);
  }
}
