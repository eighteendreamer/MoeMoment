import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 图片持久化：复制到 App 持久化目录，删除时严格按归属清理。
class ImageStorage {
  static const _lensDirName = 'lens_images';

  Future<Directory> _ensureDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}$_lensDirName');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 将选中的临时图片复制到持久化目录，返回持久化路径。
  ///
  /// 失败时抛出异常；数据库写入失败时由调用方调用 [deletePersistent]
  /// 清理已复制文件，避免孤立文件。
  Future<String> copyToPersistent(String sourcePath) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw FileSystemException('源图片不存在', sourcePath);
    }
    final dir = await _ensureDir();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final ext = _extensionOf(sourcePath);
    final targetPath = '${dir.path}${Platform.pathSeparator}img_$timestamp$ext';
    final copied = await source.copy(targetPath);
    return copied.path;
  }

  /// 删除单张已归属确认的持久化图片。
  ///
  /// 只允许删除位于 App 图片目录内的文件，禁止清理相册原图或其他记录的图片。
  Future<void> deletePersistent(String path) async {
    final docs = await getApplicationDocumentsDirectory();
    final allowed = '${docs.path}${Platform.pathSeparator}$_lensDirName'
        .replaceAll('/', Platform.pathSeparator);
    final normalized = path.replaceAll('/', Platform.pathSeparator);
    if (!normalized.startsWith(allowed)) {
      throw ArgumentError('拒绝删除 App 图片目录之外的文件: $path');
    }
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    return ext.length <= 5 ? ext : '.jpg';
  }
}
