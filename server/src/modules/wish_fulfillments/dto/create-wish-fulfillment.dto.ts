import { IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';

export class CreateWishFulfillmentDto {
  @IsOptional()
  @IsString()
  fulfillerId?: string;

  @IsString()
  actualDishName!: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  helperTasksDone?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  feedbackTags?: string[];

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsBoolean()
  addToDishes?: boolean;
}
