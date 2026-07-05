# 厨房许愿池

面向情侣、夫妻、双人小家庭的共享吃饭愿望 App。

当前项目结构：

- `app/`: Flutter 客户端
- `server/`: NestJS + Prisma 后端
- `docker-compose.yml`: Docker 部署 PostgreSQL、Redis、后端服务
- `prototype/`: 早期 HTML 原型
- `stitch-export/`: Stitch 导出的界面图和 HTML

## 目录

- [环境要求](#环境要求)
- [首次拉取项目](#首次拉取项目)
- [后端开发命令](#后端开发命令)
- [数据库和 Prisma 命令](#数据库和-prisma-命令)
- [Docker 命令](#docker-命令)
- [Flutter 开发命令](#flutter-开发命令)
- [Flutter 模拟器命令](#flutter-模拟器命令)
- [Flutter 热更新和调试命令](#flutter-热更新和调试命令)
- [Flutter 打包命令](#flutter-打包命令)
- [服务器部署命令](#服务器部署命令)
- [后续更新服务](#后续更新服务)
- [常用排障命令](#常用排障命令)

## 环境要求

后端：

- Node.js 18.18 或更高版本，推荐 Node.js 22
- pnpm 9.15.9
- Docker 和 Docker Compose

前端：

- Flutter SDK，Dart 3.4+
- iOS 开发需要 Xcode、CocoaPods
- Android 开发需要 Android Studio、Android SDK、模拟器

检查环境：

```bash
node -v
corepack --version
docker --version
docker compose version
flutter doctor
```

启用 pnpm：

```bash
corepack enable
corepack prepare pnpm@9.15.9 --activate
pnpm -v
```

## 首次拉取项目

```bash
cd /Users/sunliangrong/Desktop/caidan
```

安装后端依赖：

```bash
cd /Users/sunliangrong/Desktop/caidan/server
pnpm install
```

创建后端环境变量：

```bash
cd /Users/sunliangrong/Desktop/caidan/server
cp .env.example .env
```

创建 Docker Compose 环境变量：

```bash
cd /Users/sunliangrong/Desktop/caidan
cp .env.example .env
```

生成 Prisma Client：

```bash
cd /Users/sunliangrong/Desktop/caidan/server
pnpm prisma generate
```

安装 Flutter 依赖：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
flutter pub get
```

## 后端开发命令

进入后端目录：

```bash
cd /Users/sunliangrong/Desktop/caidan/server
```

安装依赖：

```bash
pnpm install
```

启动开发服务：

```bash
pnpm start:dev
```

普通启动：

```bash
pnpm start
```

构建后端：

```bash
pnpm build
```

启动构建后的生产服务：

```bash
pnpm start:prod
```

格式化代码：

```bash
pnpm format
```

Lint：

```bash
pnpm lint
```

运行单元测试：

```bash
pnpm test
```

运行 e2e 测试：

```bash
pnpm test:e2e
```

后端默认地址：

```text
http://localhost:3000/api
```

Swagger 文档地址：

```text
http://localhost:3000/api/docs
```

## 数据库和 Prisma 命令

进入后端目录：

```bash
cd /Users/sunliangrong/Desktop/caidan/server
```

生成 Prisma Client：

```bash
pnpm prisma generate
```

开发环境创建迁移：

```bash
pnpm prisma migrate dev --name init
```

部署环境执行已有迁移：

```bash
pnpm prisma migrate deploy
```

查看迁移状态：

```bash
pnpm prisma migrate status
```

打开 Prisma Studio：

```bash
pnpm prisma studio
```

根据数据库同步 Prisma Client：

```bash
pnpm prisma db pull
pnpm prisma generate
```

重置本地开发数据库：

```bash
pnpm prisma migrate reset
```

注意：`migrate reset` 会清空数据库，只能用于本地开发或测试库。

## Docker 命令

在项目根目录执行：

```bash
cd /Users/sunliangrong/Desktop/caidan
```

启动完整服务：

```bash
cp .env.example .env
docker compose up -d
```

重新构建并启动：

```bash
docker compose up -d --build
```

只启动 PostgreSQL 和 Redis：

```bash
docker compose up -d postgres redis
```

查看服务状态：

```bash
docker compose ps
```

查看所有日志：

```bash
docker compose logs -f
```

查看后端日志：

```bash
docker compose logs -f server
```

进入后端容器：

```bash
docker compose exec server sh
```

在容器里执行数据库迁移：

```bash
docker compose exec server pnpm prisma migrate deploy
```

重启后端：

```bash
docker compose restart server
```

停止服务：

```bash
docker compose down
```

停止服务并删除数据库数据卷：

```bash
docker compose down -v
```

注意：`docker compose down -v` 会删除 PostgreSQL 和 Redis 数据。

当前 `docker-compose.yml` 默认映射这些端口到宿主机，方便本地后端、测试和 Flutter 直接连接：

```text
3000:3000
5432:5432
6379:6379
```

生产服务器如果不希望暴露 PostgreSQL/Redis 到公网，需要在防火墙或 Compose override 中限制端口暴露。

## Flutter 开发命令

进入 Flutter 项目：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
```

安装依赖：

```bash
flutter pub get
```

清理构建缓存：

```bash
flutter clean
flutter pub get
```

查看 Flutter 环境：

```bash
flutter doctor
flutter doctor -v
```

查看可运行设备：

```bash
flutter devices
```

运行测试环境：

```bash
flutter run --dart-define-from-file=config/test.env
```

运行生产环境：

```bash
flutter run --dart-define-from-file=config/production.env
```

指定设备运行：

```bash
flutter run -d 设备ID --dart-define-from-file=config/test.env
```

覆盖单个环境变量：

```bash
flutter run --dart-define-from-file=config/test.env --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

当前环境配置文件：

- `app/config/test.env`
- `app/config/production.env`

支持的 Flutter 环境变量：

```text
APP_ENV=test|production
API_BASE_URL=后端 API 地址
```

本项目当前配置的 API 地址：

```text
http://110.42.244.187:3338/api
```

## Flutter 模拟器命令

打开 iOS 模拟器：

```bash
open -a Simulator
```

查看 iOS 模拟器列表：

```bash
xcrun simctl list devices
```

启动指定 iOS 模拟器：

```bash
xcrun simctl boot "iPhone 17"
open -a Simulator
```

在当前已跑通的 iPhone 17 模拟器运行：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
open -a Simulator
flutter run -d 1A384499-2531-4CFE-80E7-DF5C7A2D6450 --dart-define-from-file=config/test.env
```

当前已跑通的 iPhone 17 模拟器 UDID：

```text
1A384499-2531-4CFE-80E7-DF5C7A2D6450
```

查看 Flutter 模拟器：

```bash
flutter emulators
```

启动 Flutter 模拟器：

```bash
flutter emulators --launch 模拟器ID
```

Android 模拟器运行：

```bash
flutter run -d Android设备ID --dart-define-from-file=config/test.env
```

Web 运行：

```bash
flutter run -d chrome --dart-define-from-file=config/test.env
```

macOS 桌面运行：

```bash
flutter run -d macos --dart-define-from-file=config/test.env
```

## Flutter 热更新和调试命令

`flutter run` 启动后，终端常用按键：

```text
r  热重载 Hot Reload
R  热重启 Hot Restart
h  查看帮助
p  显示或隐藏调试辅助线
o  切换 iOS/Android 显示模式
d  断开终端，App 继续运行
q  退出运行
```

热重载适合改 UI 和普通 Dart 逻辑：

```text
r
```

热重启适合改初始化逻辑、路由、Provider 初始化等：

```text
R
```

如果热重载不生效，直接停止后重新运行：

```bash
flutter run --dart-define-from-file=config/test.env
```

查看详细运行日志：

```bash
flutter run -v --dart-define-from-file=config/test.env
```

查看设备日志：

```bash
flutter logs
```

分析代码：

```bash
flutter analyze
```

运行 Flutter 测试：

```bash
flutter test
```

运行指定测试文件：

```bash
flutter test test/widget_test.dart
```

## Flutter 打包命令

进入 Flutter 项目：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
```

iOS Release 包，测试环境：

```bash
flutter build ios --release --dart-define-from-file=config/test.env
```

iOS Release 包，生产环境：

```bash
flutter build ios --release --dart-define-from-file=config/production.env
```

iOS 不签名构建：

```bash
flutter build ios --release --no-codesign --dart-define-from-file=config/production.env
```

Android APK，测试环境：

```bash
flutter build apk --release --dart-define-from-file=config/test.env
```

Android APK，生产环境：

```bash
flutter build apk --release --dart-define-from-file=config/production.env
```

Android App Bundle，生产环境：

```bash
flutter build appbundle --release --dart-define-from-file=config/production.env
```

Web 打包，生产环境：

```bash
flutter build web --release --dart-define-from-file=config/production.env
```

macOS 打包，生产环境：

```bash
flutter build macos --release --dart-define-from-file=config/production.env
```

构建产物常见位置：

```text
app/build/app/outputs/flutter-apk/app-release.apk
app/build/app/outputs/bundle/release/app-release.aab
app/build/ios/iphoneos/Runner.app
app/build/web
app/build/macos/Build/Products/Release
```

## 服务器部署命令

以下命令在服务器上执行。

拉取代码：

```bash
git clone 仓库地址 caidan
cd caidan
```

如果服务器已经有项目：

```bash
cd caidan
git pull
```

设置后端生产环境变量：

```bash
cp .env.example .env
export JWT_SECRET="替换成足够长的随机字符串"
export POSTGRES_PASSWORD="替换成数据库强密码"
export POSTGRES_USER="kitchen"
export POSTGRES_DB="kitchen_wish_well"
export CORS_ORIGINS="https://你的域名"
export SWAGGER_ENABLED="false"
```

首次部署并启动：

```bash
docker compose up -d --build
docker compose exec server pnpm prisma migrate deploy
docker compose restart server
```

查看服务状态：

```bash
docker compose ps
```

查看后端日志：

```bash
docker compose logs -f server
```

服务器后端默认监听：

```text
http://服务器IP:3000/api
http://服务器IP:3000/api/docs
```

如果使用 Nginx，常见转发目标：

```text
http://127.0.0.1:3000
```

如果线上实际使用 `3338` 端口，需要在服务器 Nginx 或端口映射中把外部 `3338` 转发到后端服务。

## 后续更新服务

服务器更新后端代码：

```bash
cd caidan
git pull
docker compose up -d --build
docker compose exec server pnpm prisma migrate deploy
docker compose restart server
docker compose logs -f server
```

只重启服务：

```bash
docker compose restart server
```

只重新构建后端：

```bash
docker compose build server
docker compose up -d server
```

查看当前 Git 版本：

```bash
git log --oneline -5
```

查看本地改动：

```bash
git status
```

## 常用排障命令

查看端口占用：

```bash
lsof -i :3000
lsof -i :3338
lsof -i :5432
lsof -i :6379
```

查看 Docker 容器：

```bash
docker ps
docker compose ps
```

查看后端容器日志：

```bash
docker compose logs --tail=200 server
```

查看数据库日志：

```bash
docker compose logs --tail=200 postgres
```

进入 PostgreSQL：

```bash
docker compose exec postgres psql -U kitchen -d kitchen_wish_well
```

在 PostgreSQL 里查看表：

```sql
\dt
```

检查 Redis：

```bash
docker compose exec redis redis-cli ping
```

清理 Flutter iOS 依赖后重装：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

如果 CocoaPods 未安装：

```bash
sudo gem install cocoapods
pod --version
```

如果 Android 设备找不到：

```bash
flutter doctor -v
flutter devices
adb devices
```

如果 iOS 模拟器找不到：

```bash
open -a Simulator
xcrun simctl list devices
flutter devices
```

## 重要注意事项

- 生产环境必须设置强随机的 `JWT_SECRET` 和 `POSTGRES_PASSWORD`。
- 生产环境建议设置 `CORS_ORIGINS` 并关闭 `SWAGGER_ENABLED`。
- `docker compose down -v` 会删除数据库数据，线上不要随便执行。
- 每次后端 Prisma schema 有变化，部署后都要执行 `pnpm prisma migrate deploy`。
- Flutter 打包时一定要确认 `--dart-define-from-file` 使用的是正确环境。
- iOS 真机和正式上架还需要在 Xcode 中配置 Bundle ID、签名证书和描述文件。
