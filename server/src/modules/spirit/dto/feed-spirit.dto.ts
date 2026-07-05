import { IsIn } from 'class-validator';
import { FeedType } from '@prisma/client';

export class FeedSpiritDto {
  @IsIn(['NORMAL', 'DELICATE', 'FEAST'])
  feedType!: FeedType;
}
