import { Injectable } from '@nestjs/common';
import { MvpDataService } from '../mvp_data/mvp-data.service';
import { CreateWishResponseDto } from './dto/create-wish-response.dto';

@Injectable()
export class WishResponsesService {
  constructor(private readonly data: MvpDataService) {}

  create(wishId: string, dto: CreateWishResponseDto, userId?: string) {
    return userId ? this.data.respondToWishForUser(userId, wishId, dto) : this.data.respondToWish(wishId, dto);
  }

  confirm(responseId: string, userId?: string) {
    return userId ? this.data.confirmResponseForUser(userId, responseId) : this.data.confirmResponse(responseId);
  }

  reopen(responseId: string, userId?: string) {
    return userId ? this.data.reopenResponseForUser(userId, responseId) : this.data.reopenResponse(responseId);
  }
}
