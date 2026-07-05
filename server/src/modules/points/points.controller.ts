import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtUser } from '../auth/jwt.strategy';
import { RewardsService } from '../rewards/rewards.service';

@ApiTags('points')
@ApiBearerAuth()
@Controller('points')
export class PointsController {
  constructor(private readonly rewards: RewardsService) {}

  @Get()
  get(@CurrentUser() user: JwtUser) {
    return this.rewards.getPoints(user.id);
  }

  @Get('transactions')
  transactions(@CurrentUser() user: JwtUser) {
    return this.rewards.listPointTransactions(user.id);
  }
}
