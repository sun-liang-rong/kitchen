import { Module } from '@nestjs/common';
import { WishFulfillmentsController } from './wish-fulfillments.controller';
import { WishFulfillmentsService } from './wish-fulfillments.service';

@Module({
  controllers: [WishFulfillmentsController],
  providers: [WishFulfillmentsService],
  exports: [WishFulfillmentsService],
})
export class WishFulfillmentsModule {}
