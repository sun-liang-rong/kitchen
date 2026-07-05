import { Body, Controller, Get, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtUser } from '../auth/jwt.strategy';
import { RewardsService } from '../rewards/rewards.service';
import { FeedSpiritDto } from './dto/feed-spirit.dto';
import { RenameSpiritDto } from './dto/rename-spirit.dto';
import { UpdateSpiritStyleDto } from './dto/update-spirit-style.dto';

@ApiTags('spirit')
@ApiBearerAuth()
@Controller('spirit')
export class SpiritController {
  constructor(private readonly rewards: RewardsService) {}

  @Get()
  get(@CurrentUser() user: JwtUser) {
    return this.rewards.getSpirit(user.id);
  }

  @Patch('name')
  rename(@CurrentUser() user: JwtUser, @Body() dto: RenameSpiritDto) {
    return this.rewards.renameSpirit(user.id, dto.name);
  }

  @Patch('style')
  style(@CurrentUser() user: JwtUser, @Body() dto: UpdateSpiritStyleDto) {
    return this.rewards.updateSpiritStyle(user.id, dto.style);
  }

  @Post('feed')
  feed(@CurrentUser() user: JwtUser, @Body() dto: FeedSpiritDto) {
    return this.rewards.feed(user.id, dto.feedType);
  }

  @Get('logs')
  logs(@CurrentUser() user: JwtUser) {
    return this.rewards.listLogs(user.id);
  }
}
