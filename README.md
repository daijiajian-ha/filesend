# FileSend 企业版

> 基于 FileSend 二次开发的企业专用文件传输工具

## 功能

- ✅ 文件/文件夹传输（Windows ↔ macOS）
- ✅ 6位数字口令验证（一次性）
- ✅ 断点续传
- ✅ 传输日志（含设备IP/MAC/主机名）
- ✅ 传输完成弹窗通知

## GitHub Actions 云编译

### 方式1: 直接下载构建产物

1. 点击上方 **Actions** 标签
2. 选择 **Build FileSend**
3. 点击 **Run workflow**
4. 选择平台（windows/macos/linux）
5. 等待完成后在 Artifacts 下载

### 方式2: 本地修改后触发构建

```bash
# 1. Fork 本仓库

# 2. 克隆你的 fork
git clone https://github.com/YOUR_USERNAME/locaFileSendnd-.git
cd locaFileSendnd-

# 3. 按 MODIFICATION_GUIDE.md 修改代码

# 4. 推送并触发 Actions
git add .
git commit -m "apply code changes"
git push

# 5. 在 GitHub Actions 页面运行 workflow
```

## 目录结构

```
locaFileSendnd-/
├── SPEC.md                          # 设计规范文档
├── MODIFICATION_GUIDE.md             # 代码修改指南
├── modified/                        # 新增的服务代码
│   └── app/lib/service/
│       ├── transfer_code_service.dart
│       └── transfer_log_service.dart
└── .github/workflows/
    └── build.yml                    # GitHub Actions 构建流程
```

## 修改指南

详见 [MODIFICATION_GUIDE.md](./MODIFICATION_GUIDE.md)

## 技术栈

- Flutter 3.25+
- Dart
- archive (打包库)
- HTTPS 加密传输
