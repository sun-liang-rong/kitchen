import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  MaxLength,
} from "class-validator";

export class CreateWishFulfillmentDto {
  @IsString()
  @MaxLength(80)
  actualDishName!: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(12)
  @IsString({ each: true })
  @MaxLength(24, { each: true })
  helperTasksDone?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(12)
  @IsString({ each: true })
  @MaxLength(24, { each: true })
  feedbackTags?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;

  @IsOptional()
  @IsBoolean()
  addToDishes?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  imageUrl?: string;
}
