import { Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtUser } from '../auth/jwt.strategy';
import { RewardsService } from '../rewards/rewards.service';

@ApiTags('checkins')
@ApiBearerAuth()
@Controller('checkins')
export class CheckinsController {
  constructor(private readonly rewards: RewardsService) {}

  @Post()
  checkin(@CurrentUser() user: JwtUser) {
    return this.rewards.checkin(user.id);
  }

  @Get('status')
  status(@CurrentUser() user: JwtUser) {
    return this.rewards.getCheckinStatus(user.id);
  }
}
