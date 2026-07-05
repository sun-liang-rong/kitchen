# 厨房许愿池

面向情侣、夫妻、双人小家庭的共享吃饭愿望 App。

当前仓库按 `架构.md` 初始化为模块化单体：

- `app/`: Flutter 移动端工程骨架
- `server/`: NestJS + Prisma 后端工程骨架
- `docker-compose.yml`: 本地 PostgreSQL 和 Redis
- `prototype/`: 早期 HTML 原型
- `stitch-export/`: Stitch 导出的屏幕图片与 HTML

## 本地开发

```bash
docker compose up -d postgres redis

cd server
pnpm install
pnpm prisma generate
pnpm start:dev
```

Flutter SDK 安装后：

```bash
cd app
flutter pub get
flutter run
```

### 前端环境配置

Flutter 前端通过 `--dart-define-from-file` 区分环境，配置文件在：

- 测试环境：`app/config/test.env`
- 生产环境：`app/config/production.env`

当前支持的环境变量：

```text
APP_ENV=test|production
API_BASE_URL=后端 API 地址
```

本地运行测试环境：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
flutter run --dart-define-from-file=config/test.env
```

iOS 模拟器运行测试环境：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
open -a Simulator
flutter run -d 1A384499-2531-4CFE-80E7-DF5C7A2D6450 --dart-define-from-file=config/test.env
```

打包测试环境：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
flutter build ios --release --dart-define-from-file=config/test.env
```

打包生产环境：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
flutter build ios --release --dart-define-from-file=config/production.env
```

如果要覆盖某个变量，可以额外追加 `--dart-define`，它会覆盖配置文件里的同名变量：

```bash
flutter run --dart-define-from-file=config/test.env --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

### iOS 模拟器运行

本机已使用 iPhone 17 模拟器跑通过，设备 ID（UDID）为：

```text
1A384499-2531-4CFE-80E7-DF5C7A2D6450
```

启动模拟器并运行 App：

```bash
cd /Users/sunliangrong/Desktop/caidan/app
open -a Simulator
flutter run -d 1A384499-2531-4CFE-80E7-DF5C7A2D6450 --dart-define-from-file=config/test.env
```

查看当前可用设备：

```bash
flutter devices
```

如果只连接了一台可运行设备，也可以直接运行：

```bash
flutter run
```

`flutter run` 启动后的常用按键：

```text
r  热重载
R  热重启
d  断开终端但 App 继续留在模拟器里运行
q  退出运行
```

说明：

- `1A384499-2531-4CFE-80E7-DF5C7A2D6450` 是 iPhone 17 模拟器的唯一设备 ID。
- iOS Flutter 插件依赖 CocoaPods；如果提示 `CocoaPods not installed`，先安装 CocoaPods 后再运行。
- Android SDK 未安装不影响 iOS 模拟器运行。
