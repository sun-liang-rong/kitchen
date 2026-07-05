import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email?.trim().toLowerCase();
    const phone = dto.phone?.trim();
    if (!email && !phone) {
      throw new BadRequestException('手机号或邮箱至少填写一个');
    }

    const existing = await this.prisma.user.findFirst({
      where: {
        OR: [
          ...(email ? [{ email }] : []),
          ...(phone ? [{ phone }] : []),
        ],
      },
    });
    if (existing) {
      throw new BadRequestException('账号已存在');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email,
        phone,
        passwordHash,
        nickname: dto.nickname.trim(),
        avatarUrl: dto.avatarUrl,
        gender: dto.gender ?? 'UNSPECIFIED',
      },
      select: this.userSelect(),
    });

    return this.authPayload(user);
  }

  async login(dto: LoginDto) {
    const email = dto.email?.trim().toLowerCase();
    const phone = dto.phone?.trim();
    if (!email && !phone) {
      throw new BadRequestException('手机号或邮箱至少填写一个');
    }

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          ...(email ? [{ email }] : []),
          ...(phone ? [{ phone }] : []),
        ],
      },
    });

    const passwordValid =
      user?.passwordHash && (await bcrypt.compare(dto.password, user.passwordHash));
    if (!user || !passwordValid) {
      throw new UnauthorizedException('账号或密码错误');
    }

    return this.authPayload({
      id: user.id,
      nickname: user.nickname,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      gender: user.gender,
      createdAt: user.createdAt,
    });
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: this.userSelect(),
    });
    if (!user) {
      throw new UnauthorizedException('登录已失效');
    }
    return user;
  }

  logout() {
    return { success: true };
  }

  private authPayload(user: {
    id: string;
    nickname: string;
    email: string | null;
    phone: string | null;
    avatarUrl: string | null;
    gender: string;
    createdAt?: Date;
  }) {
    return {
      token: this.jwtService.sign({ sub: user.id }),
      user,
    };
  }

  private userSelect() {
    return {
      id: true,
      nickname: true,
      email: true,
      phone: true,
      avatarUrl: true,
      gender: true,
      createdAt: true,
    };
  }
}
