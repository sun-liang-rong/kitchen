import { IsOptional, IsString } from 'class-validator';

export class SetKitchenStatusDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsString()
  status!: string;

  @IsOptional()
  @IsString()
  note?: string;
}
