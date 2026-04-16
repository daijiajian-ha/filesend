import 'dart:math';

/// 6位数字传输口令服务
/// 用于企业版：发送方生成口令，接收方输入验证
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
