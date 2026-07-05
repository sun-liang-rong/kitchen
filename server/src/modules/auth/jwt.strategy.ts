import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../../prisma/prisma.service';

export type JwtUser = {
  id: string;
  nickname: string;
  email: string | null;
  phone: string | null;
  avatarUrl: string | null;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET ?? 'dev-kitchen-wish-well-secret',
    });
  }

  async validate(payload: { sub?: string }): Promise<JwtUser> {
    if (!payload.sub) {
      throw new UnauthorizedException('登录已失效');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        nickname: true,
        email: true,
        phone: true,
        avatarUrl: true,
      },
    });
    if (!user) {
      throw new UnauthorizedException('登录已失效');
    }
    return user;
  }
}
