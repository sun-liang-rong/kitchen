import { Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtUser } from '../auth/jwt.strategy';
import { SetKitchenStatusDto } from './dto/set-kitchen-status.dto';
import { KitchenStatusService } from './kitchen-status.service';

@ApiTags('kitchen-status')
@ApiBearerAuth()
@Controller('kitchen-status')
export class KitchenStatusController {
  constructor(private readonly kitchenStatusService: KitchenStatusService) {}

  @Get()
  findAll(@CurrentUser() user: JwtUser) {
    return this.kitchenStatusService.findAll(user.id);
  }

  @Put()
  set(@Body() dto: SetKitchenStatusDto, @CurrentUser() user: JwtUser) {
    return this.kitchenStatusService.set(user.id, dto);
  }
}
