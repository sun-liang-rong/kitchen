import { Global, Module } from '@nestjs/common';
import { RewardsService } from './rewards.service';

@Global()
@Module({
  providers: [RewardsService],
  exports: [RewardsService],
})
export class RewardsModule {}
