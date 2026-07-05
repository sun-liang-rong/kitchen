import { ArrayMaxSize, IsArray, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateWishDto {
  @IsString()
  @MaxLength(80)
  title!: string;

  @IsOptional()
  @IsIn(['DISH', 'FEELING'])
  wishType?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(12)
  @IsString({ each: true })
  @MaxLength(24, { each: true })
  feelingTags?: string[];

  @IsOptional()
  @IsIn(['TONIGHT', 'TOMORROW', 'THIS_WEEK', 'WEEKEND', 'SOMEDAY'])
  desiredTime?: string;

  @IsOptional()
  @IsIn(['CASUAL', 'THIS_WEEK', 'TODAY', 'VERY_TODAY', 'WEEKEND_PLAN'])
  intensity?: string;

  @IsOptional()
  @IsIn(['SIMILAR_OK', 'LIGHT_VERSION_OK', 'WHAT_WE_HAVE_OK', 'NO_SUBSTITUTE'])
  substituteOption?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(12)
  @IsString({ each: true })
  @MaxLength(24, { each: true })
  helperTasks?: string[];
}
