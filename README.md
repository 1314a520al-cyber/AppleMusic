# AppleMusic

一个外观与苹果自带「音乐」App 一致的 iOS 播放器。

## 特性

- **悬浮液态玻璃底部导航栏**：主页 / 广播 / 搜索 / 资料库 / 我的
- **全屏播放页**：大封面、进度拖动、歌词、队列、收藏、下载
- **三平台搜索**：网易云 / QQ 音乐 / 酷狗
- **音源管理**：粘贴 URL 或 JSON 导入，自动识别卡密
- **清除缓存**：分类统计与清理
- **赞赏 & 交流群**：我的页面入口，可自由开关
- **设置页**：所有功能开关

## 系统要求

- iOS 15.0 及以上
- 纯公开 API 实现，低版本系统也能使用

## 构建

本项目用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成工程：

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project AppleMusic.xcodeproj -scheme AppleMusic \
  -configuration Release -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

推送到 `main` 会通过 GitHub Actions 自动构建并发布未签名 IPA 到 Releases。

## 目录结构

```
Sources/
├── App/            入口与根视图
├── UI/             界面（含悬浮底栏、各页面）
├── Player/         播放引擎
├── MusicSources/   音源与三平台 API
├── Models/         数据模型与本地存储
└── Support/        基础设施（缓存、图片、下载、设置）
```

## 说明

本应用为个人学习交流用途，音乐版权归各平台所有。
