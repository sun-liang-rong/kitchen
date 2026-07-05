import { IsIn } from 'class-validator';
import { SpiritStyle } from '@prisma/client';

export class UpdateSpiritStyleDto {
  @IsIn(['FLAME', 'SHADOW', 'CELESTIAL'])
  style!: SpiritStyle;
}
