import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 图片持久化：复制到 App 支持目录，删除时严格按归属清理。
///
/// 使用 getApplicationSupportDirectory（Windows 为 %APPDATA% 下应用目录），
/// 不跟随系统「文档」重定向：部分用户文档文件夹指向可移动/网络位置，
/// 不可用时会导致复制失败（errno = 2）。与数据库目录策略一致。
class ImageStorage {
  static const _lensDirName = 'lens_images';

  Future<Directory> _ensureDir() async {
    final support = await getApplicationSupportDirectory();
    if (!support.existsSync()) {
      await support.create(recursive: true);
    }
    final dir = Directory(
      '${support.path}${Platform.pathSeparator}$_lensDirName',
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _lensDirPath() async {
    final support = await getApplicationSupportDirectory();
    return '${support.path}${Platform.pathSeparator}$_lensDirName';
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
    final allowed = (await _lensDirPath()).replaceAll(
      '/',
      Platform.pathSeparator,
    );
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
