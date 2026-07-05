import { Global, Module } from '@nestjs/common';
import { MvpDataService } from './mvp-data.service';

@Global()
@Module({
  providers: [MvpDataService],
  exports: [MvpDataService],
})
export class MvpDataModule {}
