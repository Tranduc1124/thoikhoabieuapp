import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../api/api.dart';

class BackupService {
  const BackupService({required this.userId});

  final String userId;

  Future<File> exportUserDataToJson() async {
    final data = await Api.call('backup.export');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/thoikhoabieu_backup_$userId.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data['backup']),
    );
    return file;
  }

  Future<void> importUserDataFromJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('File backup không hợp lệ.');
    }
    await Api.call('backup.import', data: {'backup': decoded});
  }
}
