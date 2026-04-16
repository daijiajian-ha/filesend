import 'dart:convert';
import 'dart:io';

/// 传输日志服务
/// 记录传输双方信息、进度、状态、错误
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
    return '$_logDir/lse-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.jsonl';
  }

  /// 写入日志
  static Future<void> log(Map<String, dynamic> entry) async {
    if (_logDir == null) return;
    
    final file = File(_logFile());
    final line = '${jsonEncode(entry)}\n';
    await file.writeAsString(line, mode: FileMode.append);
  }

  /// 记录传输开始
  static Future<void> logStart({
    required String transferId,
    required String direction, // 'send' or 'receive'
    required Map<String, String> sender, // ip, mac, hostname
    required Map<String, String> receiver,
    required String fileName,
    required int fileSize,
    required String fileHash,
    String? code,
  }) async {
    await log({
      'timestamp': DateTime.now().toIso8601String(),
      'event': 'transfer_start',
      'transferId': transferId,
      'direction': direction,
      'sender': sender,
      'receiver': receiver,
      'file': {'name': fileName, 'size': fileSize, 'hash': fileHash},
      'code': code,
    });
  }

  /// 记录传输进度
  static Future<void> logProgress({
    required String transferId,
    required int bytesSent,
    required int totalBytes,
    required double speedMBps,
  }) async {
    await log({
      'timestamp': DateTime.now().toIso8601String(),
      'event': 'transfer_progress',
      'transferId': transferId,
      'bytesSent': bytesSent,
      'totalBytes': totalBytes,
      'progress': '${((bytesSent / totalBytes) * 100).toStringAsFixed(1)}%',
      'speedMBps': speedMBps.toStringAsFixed(2),
    });
  }

  /// 记录传输完成
  static Future<void> logComplete({
    required String transferId,
    required bool hashVerified,
    required int durationSeconds,
  }) async {
    await log({
      'timestamp': DateTime.now().toIso8601String(),
      'event': 'transfer_complete',
      'transferId': transferId,
      'hashVerified': hashVerified,
      'durationSeconds': durationSeconds,
    });
  }

  /// 记录传输错误
  static Future<void> logError({
    required String transferId,
    required String error,
    int? offset,
  }) async {
    await log({
      'timestamp': DateTime.now().toIso8601String(),
      'event': 'transfer_error',
      'transferId': transferId,
      'error': error,
      'offset': offset,
    });
  }

  /// 记录口令验证结果
  static Future<void> logCodeResult({
    required String ip,
    required bool success,
    String? code,
  }) async {
    await log({
      'timestamp': DateTime.now().toIso8601String(),
      'event': success ? 'code_verified' : 'code_invalid',
      'ip': ip,
      'code': code,
    });
  }
}
