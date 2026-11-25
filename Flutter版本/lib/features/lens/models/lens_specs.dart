import 'dart:convert';

/// 镜片参数（Lens_Specs）。
///
/// JSON 键名保持需求约定的拼写与大小写，不得随意改名：
/// ```json
/// {
///   "Lens_diameter": 14.2,
///   "Colored_diameter": 13.2,
///   "Moisture_content": 48,
///   "Base_arc": 8.6,
///   "Left_eye_prescription": -3.25,
///   "right_eye_prescription": -3.50
/// }
/// ```
///
/// 六项参数允许缺失；含水量保存为数值（如 `48`），UI 展示为 `48%`。
class LensSpecs {
  const LensSpecs({
    this.lensDiameter,
    this.coloredDiameter,
    this.moistureContent,
    this.baseArc,
    this.leftEyePrescription,
    this.rightEyePrescription,
  });

  final double? lensDiameter;
  final double? coloredDiameter;
  final num? moistureContent;
  final double? baseArc;
  final double? leftEyePrescription;
  final double? rightEyePrescription;

  static const _lensDiameterKey = 'Lens_diameter';
  static const _coloredDiameterKey = 'Colored_diameter';
  static const _moistureKey = 'Moisture_content';
  static const _baseArcKey = 'Base_arc';
  static const _leftPrescriptionKey = 'Left_eye_prescription';
  static const _rightPrescriptionKey = 'right_eye_prescription';

  /// 从 JSON 文本解析；空文本或非法 JSON 返回空对象，不抛异常阻塞保存。
  factory LensSpecs.tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const LensSpecs();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const LensSpecs();
      return LensSpecs(
        lensDiameter: _toDouble(decoded[_lensDiameterKey]),
        coloredDiameter: _toDouble(decoded[_coloredDiameterKey]),
        moistureContent: _toNum(decoded[_moistureKey]),
        baseArc: _toDouble(decoded[_baseArcKey]),
        leftEyePrescription: _toDouble(decoded[_leftPrescriptionKey]),
        rightEyePrescription: _toDouble(decoded[_rightPrescriptionKey]),
      );
    } on FormatException {
      return const LensSpecs();
    }
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static num? _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    if (lensDiameter != null) _lensDiameterKey: lensDiameter,
    if (coloredDiameter != null) _coloredDiameterKey: coloredDiameter,
    if (moistureContent != null) _moistureKey: moistureContent,
    if (baseArc != null) _baseArcKey: baseArc,
    if (leftEyePrescription != null) _leftPrescriptionKey: leftEyePrescription,
    if (rightEyePrescription != null)
      _rightPrescriptionKey: rightEyePrescription,
  };

  String? encode() {
    final json = toJson();
    if (json.isEmpty) return null;
    return jsonEncode(json);
  }

  bool get isEmpty => toJson().isEmpty;
}
