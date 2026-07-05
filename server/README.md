# Kitchen Wish Well Server

NestJS backend skeleton following `架构.md`.

## Structure

- `src/common`: shared guards, filters, interceptors, DTOs, enums, utilities
- `src/config`: app, database, redis, storage configuration
- `src/prisma`: Prisma module and service
- `src/modules`: feature modules for auth, users, couples, wishes, responses, fulfillments, kitchen status, dishes, notifications, upload
- `prisma/schema.prisma`: database schema skeleton

## Development

```bash
cp .env.example .env
pnpm install
pnpm prisma generate
pnpm start:dev
```

Prisma requires Node.js 18.18 or newer.
