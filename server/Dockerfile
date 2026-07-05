FROM node:22-alpine AS base
WORKDIR /app
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
ENV PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
ENV SASS_BINARY_SITE=https://npmmirror.com/mirrors/node-sass/
RUN corepack enable && corepack prepare pnpm@9.15.9 --activate
RUN pnpm config set registry https://registry.npm.taobao.org
RUN pnpm config set strict-ssl false
RUN pnpm config set fetch-retries 5
RUN pnpm config set fetch-retry-mintimeout 10000
RUN pnpm config set fetch-retry-maxtimeout 120000

FROM base AS deps
COPY package.json pnpm-lock.yaml .npmrc ./
RUN pnpm install --frozen-lockfile

FROM deps AS build
COPY tsconfig*.json nest-cli.json ./
COPY prisma ./prisma
COPY src ./src
RUN pnpm prisma generate
RUN pnpm build
RUN pnpm prune --prod

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable && corepack prepare pnpm@9.15.9 --activate
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY package.json pnpm-lock.yaml .npmrc ./
EXPOSE 3000
CMD ["node", "dist/main.js"]
