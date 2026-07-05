import { Injectable } from '@nestjs/common';
import { SharedDataService } from '../shared_data/shared-data.service';
import { SetKitchenStatusDto } from './dto/set-kitchen-status.dto';

@Injectable()
export class KitchenStatusService {
  constructor(private readonly data: SharedDataService) {}

  findAll(userId: string) {
    return this.data.getKitchenStatusesForUser(userId);
  }

  set(userId: string, dto: SetKitchenStatusDto) {
    return this.data.setKitchenStatusForUser(userId, dto.status, dto.note);
  }
}
