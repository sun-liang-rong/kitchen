import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard';
import { JwtUser } from '../auth/jwt.strategy';
import { SetKitchenStatusDto } from './dto/set-kitchen-status.dto';
import { KitchenStatusService } from './kitchen-status.service';

@ApiTags('kitchen-status')
@ApiBearerAuth()
@UseGuards(OptionalJwtAuthGuard)
@Controller('kitchen-status')
export class KitchenStatusController {
  constructor(private readonly kitchenStatusService: KitchenStatusService) {}

  @Get()
  findAll(@CurrentUser() user?: JwtUser | null) {
    return this.kitchenStatusService.findAll(user?.id);
  }

  @Put()
  set(@Body() dto: SetKitchenStatusDto, @CurrentUser() user?: JwtUser | null) {
    return this.kitchenStatusService.set(dto, user?.id);
  }
}
