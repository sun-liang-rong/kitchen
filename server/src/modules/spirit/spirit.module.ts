import { Module } from '@nestjs/common';
import { SpiritController } from './spirit.controller';

@Module({
  controllers: [SpiritController],
})
export class SpiritModule {}
