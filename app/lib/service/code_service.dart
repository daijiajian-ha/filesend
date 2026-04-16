import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

/// 6位数字口令服务
class CodeService {
  static final _random = Random();

  /// 生成6位数字口令
  static String generateCode() {
    return String.format('%06d', _random.nextInt(999999));
  }

  /// 验证口令格式
  static bool validateCode(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }
}

/// 打包服务
class PackService {
  /// 压缩文件或文件夹为zip
  /// 返回zip文件路径
  static Future<String> packFiles(List<String> filePaths, String outputDir) async {
    // 动态import避免编译报错（如果没有archive库）
    final archive = await _getArchive();
    
    final zipFile = archive.Archive();
    
    for (final filePath in filePaths) {
      final file = File(filePath);
      if (await file.exists()) {
        final fileName = p.basename(filePath);
        final bytes = await file.readAsBytes();
        zipFile.addFile(archive.ArchiveFile(fileName, bytes.length, bytes));
      } else {
        // 处理文件夹
        final dir = Directory(filePath);
        if (await dir.exists()) {
          await _addDirectoryToArchive(archive.Archive(), dir, p.basename(filePath));
        }
      }
    }

    final outputPath = p.join(outputDir, 'transfer_${DateTime.now().millisecondsSinceEpoch}.zip');
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(archive.ZipEncoder().encode(zipFile)!);
    
    return outputPath;
  }

  /// 解压zip到目标目录
  static Future<void> unpackZip(String zipPath, String outputDir) async {
    final archive = await _getArchive();
    final bytes = await File(zipPath).readAsBytes();
    final zipFile = archive.ZipDecoder().decodeBytes(bytes);
    
    for (final file in zipFile) {
      final filePath = p.join(outputDir, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  static Future<dynamic> _getArchive() async {
    // 这里延迟import，实际编译时需要添加 archive 依赖
    return await Future.value(null);
  }

  static Future<void> _addDirectoryToArchive(dynamic archive, Directory dir, String basePath) async {
    await for (final entity in dir.list(recursive: true)) {
      final relativePath = p.join(basePath, p.relative(entity.path, from: dir.path));
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(archive.ArchiveFile(relativePath, bytes.length, bytes));
      }
    }
  }
}
