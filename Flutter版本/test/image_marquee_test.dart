import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moe_moment/features/lens/widgets/image_marquee.dart';

/// 1x1 透明 PNG，用于构造真实存在的图片文件。
const _pngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

void main() {
  late Directory dir;
  late List<String> paths;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('mm_marquee');
    paths = [
      for (var i = 0; i < 3; i++)
        (File(
          '${dir.path}${Platform.pathSeparator}img$i.png',
        )..writeAsBytesSync(_pngBytes)).path,
    ];
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  testWidgets('跑马灯：三列 6:3:1，支持自动与手动切换', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 400));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ImageMarquee(paths: paths)),
      ),
    );
    await tester.pump();

    double widthOf(ValueKey<String> key) =>
        tester.getSize(find.byKey(key)).width;

    final w0 = widthOf(ValueKey('${paths[0]}_0'));
    final w1 = widthOf(ValueKey('${paths[1]}_1'));
    final w2 = widthOf(ValueKey('${paths[2]}_2'));

    // 三列比例固定为 6:3:1。
    expect(w0 / w1, closeTo(2.0, 0.06));
    expect(w1 / w2, closeTo(3.0, 0.15));

    // 自动切换：3 秒后第 2 张移到主列（渐入动画结束后只剩一个）。
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));
    expect(widthOf(ValueKey('${paths[1]}_1')), closeTo(w0, 1.0));

    // 手动点击主图：前进到第 3 张。
    await tester.tap(find.byKey(ValueKey('${paths[1]}_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(widthOf(ValueKey('${paths[2]}_2')), closeTo(w0, 1.0));

    // 手动点击侧边图：该图移到主位。
    expect(widthOf(ValueKey('${paths[0]}_0')), lessThan(w0));
    await tester.tap(find.byKey(ValueKey('${paths[0]}_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(widthOf(ValueKey('${paths[0]}_0')), closeTo(w0, 1.0));

    // 卸载以取消定时器。
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
}
