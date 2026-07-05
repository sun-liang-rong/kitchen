import { Injectable } from '@nestjs/common';
import { MvpDataService } from '../mvp_data/mvp-data.service';
import { SetKitchenStatusDto } from './dto/set-kitchen-status.dto';

@Injectable()
export class KitchenStatusService {
  constructor(private readonly data: MvpDataService) {}

  findAll(userId?: string) {
    return userId ? this.data.getKitchenStatusesForUser(userId) : this.data.getKitchenStatuses();
  }

  set(dto: SetKitchenStatusDto, userId?: string) {
    return userId
      ? this.data.setKitchenStatusForUser(userId, dto.status, dto.note)
      : this.data.setKitchenStatus(dto.userId ?? 'me', dto.status, dto.note);
  }
}
