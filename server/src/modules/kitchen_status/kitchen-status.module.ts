import { Module } from '@nestjs/common';
import { KitchenStatusController } from './kitchen-status.controller';
import { KitchenStatusService } from './kitchen-status.service';

@Module({
  controllers: [KitchenStatusController],
  providers: [KitchenStatusService],
  exports: [KitchenStatusService],
})
export class KitchenStatusModule {}
