import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/converters.dart';
import '../../features/care_solution/care_solution_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 提醒设置页：三类提醒独立卡片。
class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key});

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
                      '提醒设置',
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
              const SizedBox(height: 6),

              // A. 美瞳到期提醒
              StreamBuilder<LensExpiryReminderSetting>(
                stream: services.careService.watchLensExpirySettings(),
                builder: (context, snapshot) {
                  final s = snapshot.data;
                  if (s == null) return const SizedBox.shrink();
                  return _LensExpiryCard(
                    isActive: s.isActive,
                    advanceDays: s.advanceDays,
                    reminderTime: s.reminderTime,
                  );
                },
              ),

              // B. 护理液更换提醒
              StreamBuilder(
                stream: services.careService.watchChangeReminder(),
                builder: (context, snapshot) {
                  final s = snapshot.data;
                  if (s == null) return const SizedBox.shrink();
                  return _CareChangeCard(
                    isActive: s.isActive,
                    frequency: ChangeFrequency.fromDb(
                      s.frequency,
                      intervalDays: s.intervalDays,
                    ),
                    intervalDays: s.intervalDays,
                    reminderTime: s.reminderTime,
                    lastChanged: s.lastChangedDate,
                    nextChanged: s.nextChangedDate,
                  );
                },
              ),

              // C. 护理液到期提醒
              StreamBuilder(
                stream: services.careService.watchExpirySettings(),
                builder: (context, snapshot) {
                  final s = snapshot.data;
                  if (s == null) return const SizedBox.shrink();
                  return _CareExpiryCard(
                    isActive: s.isActive,
                    advanceDays: s.advanceDays,
                    reminderTime: s.reminderTime,
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
}

abstract class _CardBase extends StatelessWidget {
  const _CardBase();

  Widget card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget optionRow(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: options
                .map(
                  (o) => ChoiceChip(
                    label: Text(o),
                    selected: o == selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: o == selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: o == selected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    onSelected: (_) => onSelect(o),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LensExpiryCard extends _CardBase {
  const _LensExpiryCard({
    required this.isActive,
    required this.advanceDays,
    required this.reminderTime,
  });

  final bool isActive;
  final int advanceDays;
  final String reminderTime;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return card(
      title: '美瞳到期提醒',
      icon: Icons.lens_outlined,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            '开启提醒',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          value: isActive,
          activeThumbColor: AppColors.primary,
          onChanged: (v) async {
            await services.careService.updateLensExpirySettings(
              isActive: v,
              advanceDays: advanceDays,
              reminderTime: reminderTime,
            );
            await services.reminders.resyncAll();
          },
        ),
        optionRow('提醒时间', const ['08:00', '09:00', '20:00'], reminderTime, (
          v,
        ) async {
          await services.careService.updateLensExpirySettings(
            isActive: isActive,
            advanceDays: advanceDays,
            reminderTime: v,
          );
          await services.reminders.resyncAll();
        }),
        optionRow(
          '提前天数',
          const ['提前 1 天', '提前 3 天', '提前 7 天'],
          '提前 $advanceDays 天',
          (v) async {
            final days = int.parse(v.replaceAll(RegExp(r'\D'), ''));
            await services.careService.updateLensExpirySettings(
              isActive: isActive,
              advanceDays: days,
              reminderTime: reminderTime,
            );
            await services.reminders.resyncAll();
          },
        ),
      ],
    );
  }
}

class _CareChangeCard extends _CardBase {
  const _CareChangeCard({
    required this.isActive,
    required this.frequency,
    required this.intervalDays,
    required this.reminderTime,
    this.lastChanged,
    this.nextChanged,
  });

  final bool isActive;
  final ChangeFrequency frequency;
  final int intervalDays;
  final String reminderTime;
  final String? lastChanged;
  final String? nextChanged;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final options = [
      ('每天', ChangeFrequency.daily),
      ('每 2 天', ChangeFrequency.every2Days),
      ('每 3 天', ChangeFrequency.every3Days),
      ('每周', ChangeFrequency.weekly),
      ('自定义', ChangeFrequency.custom),
    ];

    Future<void> update({
      bool? active,
      ChangeFrequency? freq,
      int? customDays,
      String? time,
    }) async {
      final effectiveFreq = freq ?? frequency;
      final interval =
          customDays ??
          (effectiveFreq == ChangeFrequency.custom
              ? intervalDays
              : effectiveFreq.defaultInterval);
      await services.careService.updateChangeReminder(
        isActive: active ?? isActive,
        frequency: effectiveFreq,
        intervalDays: interval,
        reminderTime: time ?? reminderTime,
      );
      if (freq != null || customDays != null) {
        await services.careService.recalculateNextChangeDate();
      }
      await services.reminders.resyncAll();
    }

    return card(
      title: '护理液更换提醒',
      icon: Icons.water_drop_outlined,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            '开启提醒',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          value: isActive,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => update(active: v),
        ),
        optionRow(
          '更换频率',
          options.map((o) => o.$1).toList(),
          options.where((o) => o.$2 == frequency).map((o) => o.$1).first,
          (label) {
            final freq = options.firstWhere((o) => o.$1 == label).$2;
            if (freq == ChangeFrequency.custom) {
              _askCustomDays(context, services, freq, intervalDays);
              return;
            }
            update(freq: freq);
          },
        ),
        optionRow(
          '提醒时间',
          const ['08:00', '09:00', '20:00'],
          reminderTime,
          (v) => update(time: v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '上次更换：${lastChanged ?? '未记录'} · 下次更换：${nextChanged ?? '未记录'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              final (logId, next) = await services.careService.markChanged();
              await services.reminders.resyncAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '已记录更换（#$logId），下次更换：${DateIsoConverter.encode(next)}',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('已更换护理液'),
          ),
        ),
      ],
    );
  }

  void _askCustomDays(
    BuildContext context,
    AppServices services,
    ChangeFrequency freq,
    int current,
  ) {
    final ctrl = TextEditingController(text: '$current');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          '自定义更换频率',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '间隔天数（正整数）'),
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
              final days = int.tryParse(ctrl.text.trim()) ?? 0;
              if (days <= 0) return;
              Navigator.pop(context);
              // ignore: discarded_futures
              services.careService
                  .updateChangeReminder(
                    isActive: isActive,
                    frequency: freq,
                    intervalDays: days,
                    reminderTime: reminderTime,
                  )
                  .then((_) => services.careService.recalculateNextChangeDate())
                  .then((_) => services.reminders.resyncAll());
            },
            child: const Text('确定', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _CareExpiryCard extends _CardBase {
  const _CareExpiryCard({
    required this.isActive,
    required this.advanceDays,
    required this.reminderTime,
  });

  final bool isActive;
  final int advanceDays;
  final String reminderTime;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return card(
      title: '护理液到期提醒',
      icon: Icons.event_busy_outlined,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            '开启提醒',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          value: isActive,
          activeThumbColor: AppColors.primary,
          onChanged: (v) async {
            await services.careService.updateExpirySettings(
              isActive: v,
              advanceDays: advanceDays,
              reminderTime: reminderTime,
            );
            await services.reminders.resyncAll();
          },
        ),
        optionRow('提醒时间', const ['08:00', '09:00', '20:00'], reminderTime, (
          v,
        ) async {
          await services.careService.updateExpirySettings(
            isActive: isActive,
            advanceDays: advanceDays,
            reminderTime: v,
          );
          await services.reminders.resyncAll();
        }),
        optionRow(
          '提前天数',
          const ['提前 1 天', '提前 3 天', '提前 7 天'],
          '提前 $advanceDays 天',
          (v) async {
            final days = int.parse(v.replaceAll(RegExp(r'\D'), ''));
            await services.careService.updateExpirySettings(
              isActive: isActive,
              advanceDays: days,
              reminderTime: reminderTime,
            );
            await services.reminders.resyncAll();
          },
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            '到期日期由护理液包装有效期与开封后有效天数计算，可在「护理液信息」中维护。',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
