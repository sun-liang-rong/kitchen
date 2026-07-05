import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class SetKitchenStatusDto {
  @IsIn(['SERIOUS_COOK', 'NORMAL', 'TIRED', 'SIMPLE_ONLY', 'NO_COOKING', 'COOK_TOGETHER'])
  status!: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}
