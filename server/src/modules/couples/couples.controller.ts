import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { JwtUser } from '../auth/jwt.strategy';
import { ApplyByCodeDto } from './dto/apply-by-code.dto';
import { CouplesService } from './couples.service';

@ApiTags('couples')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('couples')
export class CouplesController {
  constructor(private readonly couplesService: CouplesService) {}

  @Get('status')
  status(@CurrentUser() user: JwtUser) {
    return this.couplesService.status(user.id);
  }

  @Post('generate-code')
  generateCode(@CurrentUser() user: JwtUser) {
    return this.couplesService.generateCode(user.id);
  }

  @Post('apply-by-code')
  applyByCode(@CurrentUser() user: JwtUser, @Body() dto: ApplyByCodeDto) {
    return this.couplesService.applyByCode(user.id, dto.code);
  }

  @Post('accept/:inviteId')
  accept(@CurrentUser() user: JwtUser, @Param('inviteId') inviteId: string) {
    return this.couplesService.accept(user.id, inviteId);
  }

  @Post('reject/:inviteId')
  reject(@CurrentUser() user: JwtUser, @Param('inviteId') inviteId: string) {
    return this.couplesService.reject(user.id, inviteId);
  }

  @Post('cancel/:inviteId')
  cancel(@CurrentUser() user: JwtUser, @Param('inviteId') inviteId: string) {
    return this.couplesService.cancel(user.id, inviteId);
  }

  @Post('unbind')
  unbind(@CurrentUser() user: JwtUser) {
    return this.couplesService.unbind(user.id);
  }
}
