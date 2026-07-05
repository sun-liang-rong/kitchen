import { Controller, Get, INestApplication } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { PassportModule } from '@nestjs/passport';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtStrategy } from '../../modules/auth/jwt.strategy';
import { Public } from '../decorators/public.decorator';
import { JwtAuthGuard } from './jwt-auth.guard';

const request: any = require('supertest');

@Controller('guard-test')
class GuardTestController {
  @Get('public')
  @Public()
  publicRoute() {
    return { ok: true };
  }

  @Get('protected')
  protectedRoute() {
    return { ok: true };
  }
}

describe('JwtAuthGuard', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [PassportModule],
      controllers: [GuardTestController],
      providers: [
        JwtStrategy,
        {
          provide: PrismaService,
          useValue: {},
        },
        {
          provide: APP_GUARD,
          useClass: JwtAuthGuard,
        },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('allows public routes without a token', async () => {
    await request(app.getHttpServer()).get('/guard-test/public').expect(200);
  });

  it('rejects protected routes without a token by default', async () => {
    await request(app.getHttpServer()).get('/guard-test/protected').expect(401);
  });
});
