import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { UpdateProfileDto } from "./dto/update-profile.dto";

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: this.publicSelect(),
    });
    if (!user) {
      throw new UnauthorizedException("登录已失效");
    }
    return user;
  }

  async updateMe(userId: string, dto: UpdateProfileDto) {
    const nickname = dto.nickname?.trim();
    if (dto.nickname !== undefined && !nickname) {
      throw new BadRequestException("昵称不能为空");
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        nickname,
        avatarUrl:
          dto.avatarUrl === undefined
            ? undefined
            : dto.avatarUrl.trim() || null,
        gender: dto.gender,
      },
      select: this.publicSelect(),
    });
  }

  private publicSelect() {
    return {
      id: true,
      nickname: true,
      email: true,
      phone: true,
      avatarUrl: true,
      gender: true,
      createdAt: true,
      updatedAt: true,
    };
  }
}
