import { IsOptional, IsString, MinLength, ValidateIf } from 'class-validator';

export class LoginDto {
  @ValidateIf((dto: LoginDto) => !dto.phone)
  @IsString()
  email?: string;

  @ValidateIf((dto: LoginDto) => !dto.email)
  @IsString()
  phone?: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsOptional()
  @IsString()
  deviceName?: string;
}
