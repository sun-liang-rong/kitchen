import { Module } from '@nestjs/common';
import { WishResponsesController } from './wish-responses.controller';
import { WishResponsesService } from './wish-responses.service';

@Module({
  controllers: [WishResponsesController],
  providers: [WishResponsesService],
  exports: [WishResponsesService],
})
export class WishResponsesModule {}
