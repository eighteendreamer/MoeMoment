import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/converters.dart';
import '../../core/database/app_database.dart';
import '../../features/lens/models/lens_specs.dart';
import '../../features/lens/lens_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 添加 / 编辑美瞳页。
class LensEditPage extends StatefulWidget {
  const LensEditPage({this.lensId, super.key});

  final int? lensId;

  @override
  State<LensEditPage> createState() => _LensEditPageState();
}

class _LensEditPageState extends State<LensEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // 镜片参数
  final _lensDiameterCtrl = TextEditingController();
  final _coloredDiameterCtrl = TextEditingController();
  final _moistureCtrl = TextEditingController();
  final _baseArcCtrl = TextEditingController();
  final _leftCtrl = TextEditingController();
  final _rightCtrl = TextEditingController();

  int? _cycleId;
  List<LensCycle> _cycles = [];
  String _status = 'unopened';
  DateTime? _openedAt;
  DateTime? _packageExpiry;
  DateTime? _discardedAt;

  /// 镜片参数卡片默认收起；编辑已有参数时自动展开。
  bool _specsExpanded = false;

  // 已有图片与新增图片
  final List<ExistingImage> _existingImages = [];
  final List<int> _deleteImageIds = [];
  final List<String> _copiedNewPaths = []; // 已复制到持久化目录的新图
  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    final services = AppServicesScope.of(context);
    final cycles = await services.lensRepository.getCycles();
    if (!mounted) return;
    setState(() {
      _cycles = cycles;
      _cycleId ??= cycles.isNotEmpty ? cycles.first.id : null;
    });
    if (widget.lensId != null) {
      final detail = await services.lensRepository
          .watchLens(widget.lensId!)
          .first;
      if (detail == null || !mounted) return;
      final specs = LensSpecs.tryParse(detail.lens.lensSpecs);
      setState(() {
        _loaded = true;
        _brandCtrl.text = detail.lens.brand;
        _nameCtrl.text = detail.lens.name;
        _colorCtrl.text = detail.lens.colorScheme ?? '';
        _noteCtrl.text = detail.lens.note ?? '';
        _cycleId = detail.lens.cycleId;
        _status = detail.lens.status;
        _openedAt = DateIsoConverter.tryParse(detail.lens.openedAt);
        _packageExpiry = DateIsoConverter.tryParse(
          detail.lens.packageExpiryDate,
        );
        _discardedAt = DateIsoConverter.tryParse(detail.lens.discardedAt);
        _existingImages.addAll(detail.images.map(ExistingImage.from));
        _lensDiameterCtrl.text = specs.lensDiameter?.toString() ?? '';
        _coloredDiameterCtrl.text = specs.coloredDiameter?.toString() ?? '';
        _moistureCtrl.text = specs.moistureContent?.toString() ?? '';
        _baseArcCtrl.text = specs.baseArc?.toString() ?? '';
        _leftCtrl.text = specs.leftEyePrescription?.toString() ?? '';
        _rightCtrl.text = specs.rightEyePrescription?.toString() ?? '';
        _specsExpanded =
            specs.lensDiameter != null ||
            specs.coloredDiameter != null ||
            specs.moistureContent != null ||
            specs.baseArc != null ||
            specs.leftEyePrescription != null ||
            specs.rightEyePrescription != null;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _brandCtrl,
      _nameCtrl,
      _colorCtrl,
      _noteCtrl,
      _lensDiameterCtrl,
      _coloredDiameterCtrl,
      _moistureCtrl,
      _baseArcCtrl,
      _leftCtrl,
      _rightCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final services = AppServicesScope.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (picked == null) return;
      final path = await services.imageStorage.copyToPersistent(picked.path);
      setState(() => _copiedNewPaths.add(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  void _removeNewCopied(int index) {
    final path = _copiedNewPaths.removeAt(index);
    // 删除已复制文件；失败不阻塞编辑。
    AppServicesScope.of(context).imageStorage
        .deletePersistent(path)
        .catchError((_) {});
    setState(() {});
  }

  void _markExistingDeleted(int index) {
    final img = _existingImages.removeAt(index);
    _deleteImageIds.add(img.id);
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    final services = AppServicesScope.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_cycleId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先添加或选择周期')));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final specs = LensSpecs(
      lensDiameter: double.tryParse(_lensDiameterCtrl.text.trim()),
      coloredDiameter: double.tryParse(_coloredDiameterCtrl.text.trim()),
      moistureContent: num.tryParse(_moistureCtrl.text.trim()),
      baseArc: double.tryParse(_baseArcCtrl.text.trim()),
      leftEyePrescription: double.tryParse(_leftCtrl.text.trim()),
      rightEyePrescription: double.tryParse(_rightCtrl.text.trim()),
    );

    try {
      await services.lensRepository.saveLens(
        brand: _brandCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        cycleId: _cycleId!,
        colorScheme: _colorCtrl.text.trim().isEmpty
            ? null
            : _colorCtrl.text.trim(),
        lensSpecsJson: specs.encode(),
        status: _status,
        openedAt: _openedAt,
        packageExpiryDate: _packageExpiry,
        discardedAt: _discardedAt,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        existingId: widget.lensId,
        newImagePaths: _copiedNewPaths,
        deleteImageIds: _deleteImageIds,
      );
      await services.reminders.resyncAll();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已保存')));
        context.pop();
      }
    } catch (e) {
      // 数据库保存失败：清理本轮新复制文件，避免孤立文件。
      for (final path in List<String>.from(_copiedNewPaths)) {
        try {
          await services.imageStorage.deletePersistent(path);
        } catch (_) {}
      }
      _copiedNewPaths.clear();
      setState(() => _error = '保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCustomCycle() async {
    final services = AppServicesScope.of(context);
    final result = await showDialog<(String, String, int)>(
      context: context,
      builder: (context) => const _CustomCycleDialog(),
    );
    if (result == null) return;
    try {
      final cycle = await services.lensRepository.addCustomCycle(
        name: result.$1,
        unit: result.$2,
        value: result.$3,
      );
      final cycles = await services.lensRepository.getCycles();
      setState(() {
        _cycles = cycles;
        _cycleId = cycle.id;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('添加周期失败: $e')));
      }
    }
  }

  Future<void> _pickDate({
    required ValueChanged<DateTime> onPicked,
    DateTime? initial,
    bool allowFuture = true,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: allowFuture
          ? DateTime.now().add(const Duration(days: 3650))
          : DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 720,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.lensId == null ? '添加美瞳' : '编辑美瞳',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                _card(
                  title: '基本信息',
                  icon: Icons.style_outlined,
                  children: [
                    _pair(
                      _field(
                        '品牌',
                        _textInput(
                          _brandCtrl,
                          '如 Olens',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? '请填写品牌' : null,
                        ),
                        required: true,
                      ),
                      _field(
                        '名称',
                        _textInput(
                          _nameCtrl,
                          '如 Scandi Hazel',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? '请填写名称' : null,
                        ),
                        required: true,
                      ),
                    ),
                    _field('颜色方案', _textInput(_colorCtrl, '如 Hazel / 棕色')),
                    _pair(
                      _field(
                        '周期',
                        FSelect<int>.rich(
                          key: ValueKey(_cycleId),
                          control: FSelectControl.managed(
                            initial: _cycleId,
                            onChange: (v) {
                              if (v != null) {
                                setState(() => _cycleId = v);
                              }
                            },
                          ),
                          format: (id) {
                            final cycle = _cycles
                                .where((c) => c.id == id)
                                .firstOrNull;
                            return cycle == null
                                ? ''
                                : '${cycle.cycleName}（${cycle.cycleValue}${_unitLabel(cycle.cycleUnit)}）';
                          },
                          hint: '选择周期',
                          prefixBuilder: _selectIcon(Icons.autorenew),
                          children: _cycles
                              .map(
                                (c) => FSelectItem(
                                  title: Text(
                                    '${c.cycleName}（${c.cycleValue}${_unitLabel(c.cycleUnit)}）',
                                  ),
                                  value: c.id,
                                ),
                              )
                              .toList(),
                        ),
                        action: _labelAction(
                          icon: Icons.add,
                          label: '新建',
                          onTap: _addCustomCycle,
                        ),
                      ),
                      _field(
                        '状态',
                        FSelect<String>.rich(
                          key: ValueKey(_status),
                          control: FSelectControl.managed(
                            initial: _status,
                            onChange: (v) {
                              if (v == null) return;
                              setState(() {
                                if (v == 'opened' && _openedAt == null) {
                                  _openedAt = DateTime.now();
                                }
                                if (v == 'discarded' && _discardedAt == null) {
                                  _discardedAt = DateTime.now();
                                }
                                if (v != 'opened') _openedAt = null;
                                if (v != 'discarded') _discardedAt = null;
                                _status = v;
                              });
                            },
                          ),
                          format: (v) => LensStatus.fromDb(v).display,
                          hint: '选择状态',
                          prefixBuilder: _selectIcon(Icons.circle_outlined),
                          children: [
                            for (final status in LensStatus.values)
                              FSelectItem(
                                title: Text(status.display),
                                value: status.dbValue,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_status == 'discarded')
                      _notice('已丢弃的记录不计入使用中、未开封与已过期统计'),
                    if (_status == 'opened')
                      _field(
                        '开封日期',
                        _dateButton(
                          value: _openedAt,
                          placeholder: '选择开封日期',
                          onTap: () => _pickDate(
                            initial: _openedAt,
                            allowFuture: false,
                            onPicked: (d) => setState(() => _openedAt = d),
                          ),
                        ),
                      ),
                    _field(
                      '包装有效期（可选）',
                      _dateButton(
                        value: _packageExpiry,
                        placeholder: '未填写时不推断包装有效期',
                        onTap: () => _pickDate(
                          initial: _packageExpiry,
                          onPicked: (d) => setState(() => _packageExpiry = d),
                        ),
                      ),
                    ),
                    _field(
                      '备注',
                      _textInput(
                        _noteCtrl,
                        '佩戴感受、色差说明等',
                        maxLines: 2,
                        maxLength: 200,
                      ),
                    ),
                  ],
                ),
                _card(
                  title: '镜片参数',
                  icon: Icons.tune,
                  collapsible: true,
                  expanded: _specsExpanded,
                  subtitle: _specsSummary(),
                  onToggle: () =>
                      setState(() => _specsExpanded = !_specsExpanded),
                  children: [
                    _pair(
                      _gridField('镜片直径 (mm)', _lensDiameterCtrl, '14.2'),
                      _gridField('染色直径 (mm)', _coloredDiameterCtrl, '13.2'),
                    ),
                    _pair(
                      _gridField('含水量 (%)', _moistureCtrl, '48'),
                      _gridField('基弧 (mm)', _baseArcCtrl, '8.6'),
                    ),
                    _pair(
                      _gridField('左眼度数', _leftCtrl, '-3.25'),
                      _gridField('右眼度数', _rightCtrl, '-3.50'),
                    ),
                  ],
                ),
                _card(
                  title: '照片',
                  icon: Icons.photo_library_outlined,
                  subtitle: '支持多张，第一张作为封面',
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < _existingImages.length; i++)
                          _imageTile(
                            path: _existingImages[i].imagePath,
                            onRemove: () => _markExistingDeleted(i),
                          ),
                        for (var i = 0; i < _copiedNewPaths.length; i++)
                          _imageTile(
                            path: _copiedNewPaths[i],
                            onRemove: () => _removeNewCopied(i),
                          ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_saving ? '保存中…' : '保存'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 分区卡片：可选图标、副标题与折叠。
  Widget _card({
    required String title,
    required List<Widget> children,
    IconData? icon,
    String? subtitle,
    bool collapsible = false,
    bool expanded = true,
    VoidCallback? onToggle,
  }) {
    final header = Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (collapsible)
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.expand_more,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (collapsible)
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: header,
              ),
            )
          else
            header,
          if (collapsible)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: expanded ? 1 : 0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) =>
                  FCollapsible(value: value, child: child!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 两列并排；窄屏时自动改为上下堆叠。
  Widget _pair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [left, right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  /// 提示条：用于状态说明等辅助信息。
  Widget _notice(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// FSelect 的前置图标。
  Widget Function(BuildContext, FTextFieldStyle, Set<FTextFieldVariant>)
  _selectIcon(IconData icon) {
    return (context, style, variants) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Icon(icon, size: 16, color: AppColors.primary),
    );
  }

  /// 标签行右侧的轻量操作（如「新建」自定义周期）。
  Widget _labelAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    Widget child, {
    bool required = false,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  letterSpacing: 0.2,
                  color: AppColors.textSecondary,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              if (action != null) ...[const Spacer(), action],
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _textInput(
    TextEditingController ctrl,
    String hint, {
    FormFieldValidator<String>? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _gridField(String label, TextEditingController ctrl, String hint) {
    return _field(
      label,
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDecoration(hint),
      ),
    );
  }

  /// 已填写的镜片参数摘要，收起时作为副标题展示。
  String _specsSummary() {
    final parts = <String>[];
    final lensDiameter = _lensDiameterCtrl.text.trim();
    final coloredDiameter = _coloredDiameterCtrl.text.trim();
    final moisture = _moistureCtrl.text.trim();
    final baseArc = _baseArcCtrl.text.trim();
    final left = _leftCtrl.text.trim();
    final right = _rightCtrl.text.trim();
    if (lensDiameter.isNotEmpty) parts.add('直径 $lensDiameter');
    if (coloredDiameter.isNotEmpty) parts.add('着色 $coloredDiameter');
    if (moisture.isNotEmpty) parts.add('含水 $moisture%');
    if (baseArc.isNotEmpty) parts.add('基弧 $baseArc');
    if (left.isNotEmpty || right.isNotEmpty) {
      parts.add(
        '度数 ${left.isEmpty ? '—' : left} / ${right.isEmpty ? '—' : right}',
      );
    }
    return parts.isEmpty ? '选填 · 直径、含水量、基弧与度数' : parts.join(' · ');
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  Widget _dateButton({
    required DateTime? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? placeholder : DateIsoConverter.encode(value),
                style: TextStyle(
                  fontSize: value == null ? 13 : 14,
                  color: value == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageTile({required String path, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(path),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 84,
              height: 84,
              color: AppColors.primaryLight,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class ExistingImage {
  const ExistingImage(this.id, this.imagePath);

  factory ExistingImage.from(LensImage image) =>
      ExistingImage(image.id, image.imagePath);

  final int id;
  final String imagePath;
}

class _CustomCycleDialog extends StatefulWidget {
  const _CustomCycleDialog();

  @override
  State<_CustomCycleDialog> createState() => _CustomCycleDialogState();
}

class _CustomCycleDialogState extends State<_CustomCycleDialog> {
  final _nameCtrl = TextEditingController();
  String _unit = 'day';
  final _valueCtrl = TextEditingController(text: '10');

  static const _units = [
    ('day', '天'),
    ('week', '周'),
    ('month', '月'),
    ('year', '年'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text(
        '自定义周期',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '周期名称（如 10 天抛）'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '数值（正整数）'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FSelect<String>.rich(
                  control: FSelectControl.managed(
                    initial: _unit,
                    onChange: (v) {
                      if (v != null) {
                        setState(() => _unit = v);
                      }
                    },
                  ),
                  format: _unitLabel,
                  hint: '单位',
                  children: _units
                      .map((u) => FSelectItem(title: Text(u.$2), value: u.$1))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '取消',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_valueCtrl.text.trim()) ?? 0;
            if (value <= 0) return;
            final name = _nameCtrl.text.trim().isEmpty
                ? '${_valueCtrl.text.trim()}${_unitLabel(_unit)}'
                : _nameCtrl.text.trim();
            Navigator.pop(context, (name, _unit, value));
          },
          child: const Text('添加', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}

String _unitLabel(String unit) => switch (unit) {
  'day' => '天',
  'week' => '周',
  'month' => '月',
  'year' => '年',
  _ => unit,
};
