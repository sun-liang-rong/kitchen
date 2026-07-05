import { IsEmail, IsIn, IsOptional, IsString, MinLength, ValidateIf } from 'class-validator';

export class RegisterDto {
  @ValidateIf((dto: RegisterDto) => !dto.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((dto: RegisterDto) => !dto.email)
  @IsString()
  phone?: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsString()
  nickname!: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @IsOptional()
  @IsString()
  @IsIn(['MALE', 'FEMALE', 'UNSPECIFIED'])
  gender?: 'MALE' | 'FEMALE' | 'UNSPECIFIED';
}
