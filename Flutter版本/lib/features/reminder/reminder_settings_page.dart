import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/converters.dart';
import '../../features/care_solution/care_solution_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 提醒设置页：三类提醒独立卡片。
/// 卡片布局：标题行（图标 + 名称 + 开关）→ 开关关闭时收起选项区。
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
                  return _Stagger(
                    index: 0,
                    child: _LensExpiryCard(
                      isActive: s.isActive,
                      advanceDays: s.advanceDays,
                      reminderTime: s.reminderTime,
                    ),
                  );
                },
              ),

              // B. 护理液更换提醒
              StreamBuilder(
                stream: services.careService.watchChangeReminder(),
                builder: (context, snapshot) {
                  final s = snapshot.data;
                  if (s == null) return const SizedBox.shrink();
                  return _Stagger(
                    index: 1,
                    child: _CareChangeCard(
                      isActive: s.isActive,
                      frequency: ChangeFrequency.fromDb(
                        s.frequency,
                        intervalDays: s.intervalDays,
                      ),
                      intervalDays: s.intervalDays,
                      reminderTime: s.reminderTime,
                      lastChanged: s.lastChangedDate,
                      nextChanged: s.nextChangedDate,
                    ),
                  );
                },
              ),

              // C. 护理液到期提醒
              StreamBuilder(
                stream: services.careService.watchExpirySettings(),
                builder: (context, snapshot) {
                  final s = snapshot.data;
                  if (s == null) return const SizedBox.shrink();
                  return _Stagger(
                    index: 2,
                    child: _CareExpiryCard(
                      isActive: s.isActive,
                      advanceDays: s.advanceDays,
                      reminderTime: s.reminderTime,
                    ),
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

/// 入场动画：按索引交错淡入上移，无控制器。
class _Stagger extends StatelessWidget {
  const _Stagger({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        // 将整体进度按索引错开为每张卡片的独立进度。
        final p = (t * 3 - index).clamp(0.0, 1.0);
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - p)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 通用提醒卡片：标题行（图标 + 名称 + FSwitch）+ 可折叠选项区。
class _RemindCard extends StatelessWidget {
  const _RemindCard({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final IconData icon;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              FSwitch(value: isActive, onChange: onToggle),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: isActive
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const Padding(
              padding: EdgeInsets.only(top: 10, left: 2),
              child: Text(
                '提醒已关闭，开启后按所选时间安排通知。',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// 选项组：左侧标签 + 右侧紧凑胶囊选项。
class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: SizedBox(
              width: 62,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (o) => _Chip(
                      label: o,
                      selected: o == selected,
                      onSelected: (_) => onSelect(o),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 紧凑胶囊选项。
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: onSelected,
    );
  }
}

/// 组间分割线。
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      height: 1,
      color: AppColors.divider,
    );
  }
}

/// 更换记录信息块（上次 / 下次）。
class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LensExpiryCard extends StatelessWidget {
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
    return _RemindCard(
      title: '美瞳到期提醒',
      icon: Icons.lens_outlined,
      isActive: isActive,
      onToggle: (v) async {
        await services.careService.updateLensExpirySettings(
          isActive: v,
          advanceDays: advanceDays,
          reminderTime: reminderTime,
        );
        await services.reminders.resyncAll();
      },
      children: [
        _ChipGroup(
          label: '提醒时间',
          options: const ['08:00', '09:00', '20:00'],
          selected: reminderTime,
          onSelect: (v) async {
            await services.careService.updateLensExpirySettings(
              isActive: isActive,
              advanceDays: advanceDays,
              reminderTime: v,
            );
            await services.reminders.resyncAll();
          },
        ),
        const _GroupDivider(),
        _ChipGroup(
          label: '提前天数',
          options: const ['提前 1 天', '提前 3 天', '提前 7 天'],
          selected: '提前 $advanceDays 天',
          onSelect: (v) async {
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

class _CareChangeCard extends StatelessWidget {
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

    return _RemindCard(
      title: '护理液更换提醒',
      icon: Icons.water_drop_outlined,
      isActive: isActive,
      onToggle: (v) => update(active: v),
      children: [
        _ChipGroup(
          label: '更换频率',
          options: options.map((o) => o.$1).toList(),
          selected: options
              .where((o) => o.$2 == frequency)
              .map((o) => o.$1)
              .first,
          onSelect: (label) {
            final freq = options.firstWhere((o) => o.$1 == label).$2;
            if (freq == ChangeFrequency.custom) {
              _askCustomDays(context, services, freq, intervalDays);
              return;
            }
            update(freq: freq);
          },
        ),
        _ChipGroup(
          label: '提醒时间',
          options: const ['08:00', '09:00', '20:00'],
          selected: reminderTime,
          onSelect: (v) => update(time: v),
        ),
        const _GroupDivider(),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: _DateBox(label: '上次更换', value: lastChanged ?? '未记录'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateBox(label: '下次更换', value: nextChanged ?? '未记录'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
        content: FTextField(
          control: FTextFieldControl.managed(controller: ctrl),
          label: const Text('间隔天数（正整数）'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.dispose();
            },
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
              ctrl.dispose();
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

class _CareExpiryCard extends StatelessWidget {
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
    return _RemindCard(
      title: '护理液到期提醒',
      icon: Icons.event_busy_outlined,
      isActive: isActive,
      onToggle: (v) async {
        await services.careService.updateExpirySettings(
          isActive: v,
          advanceDays: advanceDays,
          reminderTime: reminderTime,
        );
        await services.reminders.resyncAll();
      },
      children: [
        _ChipGroup(
          label: '提醒时间',
          options: const ['08:00', '09:00', '20:00'],
          selected: reminderTime,
          onSelect: (v) async {
            await services.careService.updateExpirySettings(
              isActive: isActive,
              advanceDays: advanceDays,
              reminderTime: v,
            );
            await services.reminders.resyncAll();
          },
        ),
        const _GroupDivider(),
        _ChipGroup(
          label: '提前天数',
          options: const ['提前 1 天', '提前 3 天', '提前 7 天'],
          selected: '提前 $advanceDays 天',
          onSelect: (v) async {
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
          padding: EdgeInsets.only(top: 10, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 13,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '到期日期由护理液包装有效期与开封后有效天数计算，可在「护理液信息」中维护。',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
