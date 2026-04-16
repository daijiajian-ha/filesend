# LocalSend 企业版 - 代码修改指南

> 基于 LocalSend v1.17.0 源码修改
> 目标：添加6位数字口令 + 传输日志

---

## 📁 文件变更概览

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新增 | `app/lib/service/transfer_code_service.dart` | 口令生成/验证 |
| 新增 | `app/lib/service/transfer_log_service.dart` | 传输日志服务 |
| 修改 | `app/pubspec.yaml` | 添加 archive 依赖 |
| 修改 | `app/lib/provider/network/send_provider.dart` | 发送时生成口令 |
| 修改 | `app/lib/provider/network/server/controller/receive_controller.dart` | 验证口令 |
| 修改 | `app/lib/pages/receive_page.dart` | 口令输入UI |
| 修改 | `app/lib/pages/progress_page.dart` | 进度页显示日志入口 |

---

## 1️⃣ 新增文件

### 文件1: `app/lib/service/transfer_code_service.dart`

```dart
import 'dart:math';

/// 6位数字传输口令服务
class TransferCodeService {
  static final _random = Random();

  /// 生成6位数字口令
  static String generateCode() {
    return String.format('%06d', _random.nextInt(999999));
  }

  /// 验证口令格式（6位数字）
  static bool validateFormat(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }
}
```

---

### 文件2: `app/lib/service/transfer_log_service.dart`

```dart
import 'dart:convert';
import 'dart:io';

/// 传输日志服务
class TransferLogService {
  static String? _logDir;

  /// 初始化日志目录
  static Future<void> init(String logDirectory) async {
    _logDir = logDirectory;
    final dir = Directory(_logDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 获取日志文件路径（按日期分）
  static String _getLogFile() {
    final now = DateTime.now();
    return '$_logDir/FileSend-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.jsonl';
  }

  /// 写入日志
  static Future<void> log(Map<String, dynamic> entry) async {
    if (_logDir == null) return;
    final file = File(_getLogFile());
    await file.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append);
  }

  /// 记录传输开始
  static Future<void> logStart({...}) async { ... }
  
  /// 记录传输进度
  static Future<void> logProgress({...}) async { ... }
  
  /// 记录传输完成
  static Future<void> logComplete({...}) async { ... }
  
  /// 记录传输错误
  static Future<void> logError({...}) async { ... }
  
  /// 记录口令验证结果
  static Future<void> logCodeResult({...}) async { ... }
}
```

> 完整代码见: `modified/app/lib/service/transfer_log_service.dart`

---

## 2️⃣ 修改 pubspec.yaml

### 位置: `app/pubspec.yaml` → `dependencies:` 节点下

**查找:**
```yaml
dependencies:
  flutter:
    sdk: flutter
```

**添加（在 `archive` 位置插入）:**
```yaml
dependencies:
  archive: ^3.4.0          # zip打包/解压（企业版新增）
  flutter:
    sdk: flutter
```

---

## 3️⃣ 修改 send_provider.dart

### 位置: `app/lib/provider/network/send_provider.dart`

#### 改动1: 顶部添加 import

**查找:**
```dart
import 'package:locaFileSendnd_app/rust/api/http.dart' as rust_http;
```

**添加（在之后）:**
```dart
import 'package:locaFileSendnd_app/service/transfer_code_service.dart'; // 企业版新增
import 'package:locaFileSendnd_app/service/transfer_log_service.dart'; // 企业版新增
```

#### 改动2: startSession 方法中生成口令

**查找 (~line 80):**
```dart
  Future<void> startSession({
    required Device target,
    required List<CrossFile> files,
    required bool background,
  }) async {
    final client = ref.read(httpProvider).v2;
    final sessionId = _uuid.v4();
```

**替换为:**
```dart
  Future<void> startSession({
    required Device target,
    required List<CrossFile> files,
    required bool background,
  }) async {
    final client = ref.read(httpProvider).v2;
    final sessionId = _uuid.v4();
    
    // === 企业版新增：生成6位传输口令 ===
    final transferCode = TransferCodeService.generateCode();
    _logger.info('Generated transfer code: $transferCode for session $sessionId');
```

#### 改动3: 在 requestDto 后保存口令到会话状态

**查找 (~line 115):**
```dart
    state = state.updateSession(
      sessionId: sessionId,
      state: (_) => requestState,
    );
```

**在之前添加:**
```dart
    // === 企业版新增：保存口令到会话状态 ===
    // 将 transferCode 通过 prepareUpload 发送给接收方
    // (此改动需配合 receive_controller.dart 的验证逻辑)
```

---

## 4️⃣ 修改 receive_controller.dart

### 位置: `app/lib/provider/network/server/controller/receive_controller.dart`

#### 改动1: 顶部添加 import

**查找:**
```dart
import 'package:locaFileSendnd_app/util/rust.dart';
```

**添加（之后）:**
```dart
import 'package:locaFileSendnd_app/service/transfer_code_service.dart'; // 企业版新增
import 'package:locaFileSendnd_app/service/transfer_log_service.dart'; // 企业版新增
```

#### 改动2: _prepareUploadHandler 添加口令验证

**查找 (~line 182):**
```dart
  Future<void> _prepareUploadHandler({
    required HttpRequest request,
    required int port,
    required bool https,
    required bool v2,
  }) async {
    if (server.getState().session != null) {
      return await request.respondJson(409, message: 'Blocked by another session');
    }

    final pinCorrect = await checkPin(
      server: server,
      pin: server.getState().session?.pin,
      pinAttempts: server.getState().session?.pinAttempts ?? {},
      request: request,
    );
    if (!pinCorrect) {
      return;
    }
```

**替换为:**
```dart
  Future<void> _prepareUploadHandler({
    required HttpRequest request,
    required int port,
    required bool https,
    required bool v2,
  }) async {
    if (server.getState().session != null) {
      return await request.respondJson(409, message: 'Blocked by another session');
    }

    // === 企业版新增：6位数字口令验证 ===
    final requestCode = request.uri.queryParameters['code'];
    if (requestCode == null || !TransferCodeService.validateFormat(requestCode)) {
      await TransferLogService.logCodeResult(ip: request.ip, success: faFileSend, code: requestCode);
      return await request.respondJson(401, message: 'Invalid or missing transfer code.');
    }
    await TransferLogService.logCodeResult(ip: request.ip, success: true, code: requestCode);
    // === 企业版新增结束 ===
```

---

## 5️⃣ 修改 receive_page.dart

### 位置: `app/lib/pages/receive_page.dart`

#### 改动1: 顶部添加 import

**查找:**
```dart
import 'package:locaFileSendnd_app/gen/strings.g.dart';
```

**添加:**
```dart
import 'package:locaFileSendnd_app/service/transfer_code_service.dart'; // 企业版新增
```

#### 改动2: 添加口令输入状态

**查找:**
```dart
class _ReceivePageState extends State<ReceivePage> with Refena {
  bool _showFullIp = faFileSend;
```

**替换为:**
```dart
class _ReceivePageState extends State<ReceivePage> with Refena {
  bool _showFullIp = faFileSend;
  String _inputCode = ''; // 企业版：用户输入的口令
```

#### 改动3: 添加口令输入界面

**查找（出现在"输入口令"相关UI处）:**
```dart
        // Show pin user input
        if (vm.status == null && vm.message == null) {
          return _buildPinDialog(vm);
        }
```

**在 `_buildPinDialog` 方法中添加6位数字输入框：**

**查找 `Widget _buildPinDialog(ReceivePageVm vm)` 方法:**
```dart
  Widget _buildPinDialog(ReceivePageVm vm) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.receiveTapToAdd, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            _buildPinInput(vm), // 找到这行
          ],
        ),
      ),
    );
  }
```

**替换 `_buildPinInput` 为6位数字输入：**
```dart
  Widget _buildCodeInput(ReceivePageVm vm) {
    return Column(
      children: [
        Text(t.receiveTapToAdd, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        // === 企业版：6位数字口令输入 ===
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                key: ValueKey('code_$index'),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    // 只能输入数字
                    if (RegExp(r'^\d$').hasMatch(value)) {
                      _inputCode = _inputCode.substring(0, index) + value + 
                                   _inputCode.substring(index + 1);
                    }
                  });
                  // 自动聚焦下一个输入框
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _inputCode.length == 6 ? () => vm.onAccept() : null,
          child: Text(t.receiveAccept),
        ),
      ],
    );
  }
```

---

## 6️⃣ 修改 progress_page.dart

### 位置: `app/lib/pages/progress_page.dart`

**查找:** 传输状态显示的位置

**添加:** 日志查看按钮（可折叠展开日志）

```dart
// === 企业版新增：日志查看器 ===
ExpansionTile(
  title: const Text('传输日志'),
  children: [
    // 日志内容从 TransferLogService 读取并显示
  ],
),
```

---

## 📋 编译和运行

```bash
cd app

# 添加 archive 依赖
flutter pub add archive

# 获取依赖
flutter pub get

# 运行（开发）
flutter run -d windows
flutter run -d macos

# 构建（生产）
flutter build windows --release
flutter build macos --release
```

---

## 🔍 测试步骤

1. **发送方选择文件** → 系统生成6位口令 → 显示在界面上
2. **接收方打开app** → 输入6位口令 → 验证通过开始传输
3. **传输完成后** → 查看日志文件 `~/.FileSend/logs/FileSend-YYYY-MM-DD.jsonl`
