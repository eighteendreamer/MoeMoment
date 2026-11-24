import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/converters.dart';
import '../../core/date/date_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 护理液信息页：瓶体列表、新增/编辑、更换历史。
class CareSolutionPage extends StatelessWidget {
  const CareSolutionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 720,
          child: ListView(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '护理液信息',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editBottle(context, services, null),
                    icon: const Icon(Icons.add, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              StreamBuilder<List<CareSolutionBottle>>(
                stream: services.careService.watchBottles(),
                builder: (context, snapshot) {
                  final bottles = snapshot.data ?? const <CareSolutionBottle>[];
                  if (bottles.isEmpty) {
                    return const EmptyState(
                      message: '还没有护理液记录，点击右上角 + 添加',
                      icon: Icons.water_drop_outlined,
                    );
                  }
                  return Column(
                    children: bottles
                        .map((bottle) => _BottleCard(bottle: bottle))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: '更换历史', icon: Icons.history),
              StreamBuilder(
                stream: services.careService.watchChangeLogs(),
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? const <CareSolutionChangeLog>[];
                  if (logs.isEmpty) {
                    return const EmptyState(
                      message: '暂无更换记录',
                      icon: Icons.history_toggle_off,
                    );
                  }
                  return Column(
                    children: logs
                        .map(
                          (log) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '更换于 ${DateIsoConverter.encode(log.changedAt)}'
                                    '${(log.note ?? '').isNotEmpty ? ' · ${log.note}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _editBottle(
    BuildContext context,
    AppServices services,
    CareSolutionBottle? bottle,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _BottleForm(bottle: bottle),
    );
    // 弹层关闭后重排提醒（当前瓶信息可能变化）。
    await services.reminders.resyncAll();
  }
}

class _BottleCard extends StatelessWidget {
  const _BottleCard({required this.bottle});

  final CareSolutionBottle bottle;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final expiry = services.careService.bottleExpiryDate(bottle);
    final datesMissing = expiry == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bottle.isCurrent ? AppColors.primary : AppColors.divider,
          width: bottle.isCurrent ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${bottle.brand} · ${bottle.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (bottle.isCurrent)
                const StatusChip.label(
                  '使用中',
                  AppColors.success,
                  AppColors.successBg,
                ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    await CareSolutionPage._editBottle(
                      context,
                      services,
                      bottle,
                    );
                  } else if (action == 'toggleCurrent') {
                    await services.careService.saveBottle(
                      brand: bottle.brand,
                      name: bottle.name,
                      openedAt: DateIsoConverter.tryParse(bottle.openedAt),
                      packageExpiryDate: DateIsoConverter.tryParse(
                        bottle.packageExpiryDate,
                      ),
                      afterOpenValidDays: bottle.afterOpenValidDays,
                      isCurrent: !bottle.isCurrent,
                      note: bottle.note,
                      existingId: bottle.id,
                    );
                    await services.reminders.resyncAll();
                  } else if (action == 'delete') {
                    await services.careService.deleteBottle(bottle.id);
                    await services.reminders.resyncAll();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('编辑')),
                  PopupMenuItem(
                    value: 'toggleCurrent',
                    child: Text('切换「使用中」标记'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '开封：${bottle.openedAt ?? '未记录'}'
            ' · 包装有效期：${bottle.packageExpiryDate ?? '未记录'}'
            ' · 开封后有效：${bottle.afterOpenValidDays == null ? '未记录' : '${bottle.afterOpenValidDays} 天'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (datesMissing)
            const Text(
              '缺少到期依据，请补充包装有效期或开封后有效天数',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            )
          else
            DueChip(
              expiryDate: expiry,
              daysRemaining: const DateService().daysRemaining(expiry),
            ),
        ],
      ),
    );
  }
}

class _BottleForm extends StatefulWidget {
  const _BottleForm({this.bottle});

  final CareSolutionBottle? bottle;

  @override
  State<_BottleForm> createState() => _BottleFormState();
}

class _BottleFormState extends State<_BottleForm> {
  late final TextEditingController _brand;
  late final TextEditingController _name;
  late final TextEditingController _days;
  DateTime? _openedAt;
  DateTime? _packageExpiry;
  bool _isCurrent = false;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final b = widget.bottle;
    _brand = TextEditingController(text: b?.brand ?? '');
    _name = TextEditingController(text: b?.name ?? '');
    _days = TextEditingController(
      text: b?.afterOpenValidDays?.toString() ?? '',
    );
    _openedAt = DateIsoConverter.tryParse(b?.openedAt);
    _packageExpiry = DateIsoConverter.tryParse(b?.packageExpiryDate);
    _isCurrent = b?.isCurrent ?? false;
    _note = TextEditingController(text: b?.note ?? '');
  }

  @override
  void dispose() {
    _brand.dispose();
    _name.dispose();
    _days.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_brand.text.trim().isEmpty || _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写品牌和名称')));
      return;
    }
    final services = AppServicesScope.of(context);
    await services.careService.saveBottle(
      brand: _brand.text.trim(),
      name: _name.text.trim(),
      openedAt: _openedAt,
      packageExpiryDate: _packageExpiry,
      afterOpenValidDays: int.tryParse(_days.text.trim()),
      isCurrent: _isCurrent,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      existingId: widget.bottle?.id,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bottle == null ? '添加护理液' : '编辑护理液',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: '品牌'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateFieldButton(
                    label: '开封日期',
                    value: _openedAt,
                    onPicked: (d) => setState(() => _openedAt = d),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateFieldButton(
                    label: '包装有效期',
                    value: _packageExpiry,
                    onPicked: (d) => setState(() => _packageExpiry = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '开封后有效天数'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                '设为当前使用',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _isCurrent,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _isCurrent = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _save,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFieldButton extends StatelessWidget {
  const _DateFieldButton({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 1825)),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              current == null ? '未选择' : DateIsoConverter.encode(current),
              style: TextStyle(
                fontSize: 13,
                color: current == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
