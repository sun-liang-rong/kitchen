import { ArrayMaxSize, IsArray, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { WishResponseType } from '../../shared_data/shared-data.service';

export class CreateWishResponseDto {
  @IsIn(['FULFILL_TONIGHT', 'LIGHT_VERSION', 'ALTERNATIVE', 'DEFER', 'TOGETHER', 'SHELVE'])
  responseType!: WishResponseType;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  proposedTitle?: string;

  @IsOptional()
  @IsIn(['TONIGHT', 'TOMORROW', 'THIS_WEEK', 'WEEKEND', 'SOMEDAY'])
  proposedTime?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(12)
  @IsString({ each: true })
  @MaxLength(24, { each: true })
  reasonTags?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(300)
  reasonText?: string;
}
