import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class AddEditScheduleScreen extends ConsumerStatefulWidget {
  const AddEditScheduleScreen({super.key, this.schedule});

  final ScheduleModel? schedule;

  @override
  ConsumerState<AddEditScheduleScreen> createState() =>
      _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends ConsumerState<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _teacherController = TextEditingController();
  final _noteController = TextEditingController();

  late int _dayOfWeek;
  late int _startTime;
  late int _endTime;
  late int _color;
  late bool _repeatWeekly;
  late bool _reminderEnabled;
  late int _reminderMinutesBefore;
  bool _saving = false;

  static const _palettes = [
    _ColorChoice('Blue', 0xFF5B8CFF),
    _ColorChoice('Purple', 0xFF7C5CFF),
    _ColorChoice('Pink', 0xFFFF6FAE),
    _ColorChoice('Orange', 0xFFFF9F5A),
    _ColorChoice('Teal', 0xFF14B8A6),
    _ColorChoice('Green', 0xFF22C55E),
    _ColorChoice('Red', 0xFFF87171),
    _ColorChoice('Indigo', 0xFF6366F1),
    _ColorChoice('Cyan', 0xFF06B6D4),
    _ColorChoice('Amber', 0xFFF59E0B),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.schedule ?? ScheduleModel.empty();
    _subjectController.text = initial.subjectName;
    _roomController.text = initial.room;
    _teacherController.text = initial.teacher;
    _noteController.text = initial.note;
    _dayOfWeek = initial.dayOfWeek;
    _startTime = initial.startTime;
    _endTime = initial.endTime;
    _color = initial.color;
    _repeatWeekly = initial.repeatWeekly;
    _reminderEnabled = initial.reminderEnabled;
    _reminderMinutesBefore = initial.reminderMinutesBefore;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;
    final reminderOptions = {5, 10, 15, 30, 60, _reminderMinutesBefore}.toList()
      ..sort();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Sá»­a mÃ´n há»c' : 'ThÃªm mÃ´n há»c'),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'XoÃ¡',
            ),
        ],
      ),
      body: SoftGradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
              children: [
                const SectionHeader(
                  title: 'Chi tiáº¿t lá»‹ch há»c',
                  subtitle:
                      'Thiáº¿t láº­p mÃ´n há»c, thá»i gian vÃ  nháº¯c nhá»Ÿ',
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'ThÃ´ng tin mÃ´n há»c',
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'TÃªn mÃ´n há»c',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'KhÃ´ng Ä‘á»ƒ trá»‘ng tÃªn mÃ´n'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _teacherController,
                      decoration: const InputDecoration(
                        labelText: 'GiÃ¡o viÃªn',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Thá»i gian',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          ChoiceChip(
                            selected: _dayOfWeek == day,
                            label: Text(dayName(day)),
                            onSelected: (_) => setState(() => _dayOfWeek = day),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeTile(
                            label: 'Báº¯t Ä‘áº§u',
                            value: formatMinutes(_startTime),
                            onTap: () async {
                              final picked = await _pickTime(_startTime);
                              if (picked != null) {
                                setState(() => _startTime = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeTile(
                            label: 'Káº¿t thÃºc',
                            value: formatMinutes(_endTime),
                            onTap: () async {
                              final picked = await _pickTime(_endTime);
                              if (picked != null) {
                                setState(() => _endTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Äá»‹a Ä‘iá»ƒm & ghi chÃº',
                  children: [
                    TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(
                        labelText: 'PhÃ²ng há»c',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chÃº',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'MÃ u sáº¯c',
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        for (final choice in _palettes)
                          _ColorDot(
                            choice: choice,
                            selected: _color == choice.value,
                            onTap: () => setState(() => _color = choice.value),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Nháº¯c nhá»Ÿ',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _repeatWeekly,
                      onChanged: (value) =>
                          setState(() => _repeatWeekly = value),
                      title: const Text('Láº·p láº¡i hÃ ng tuáº§n'),
                      secondary: const Icon(Icons.repeat_rounded),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _reminderEnabled,
                      onChanged: (value) =>
                          setState(() => _reminderEnabled = value),
                      title: const Text('Nháº¯c trÆ°á»›c giá» há»c'),
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                    ),
                    if (_reminderEnabled)
                      DropdownButtonFormField<int>(
                        initialValue: _reminderMinutesBefore,
                        decoration: const InputDecoration(
                          labelText: 'Nháº¯c trÆ°á»›c',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: reminderOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value == 60 ? '1 giờ' : '$value phút',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(
                          () => _reminderMinutesBefore = value ?? 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    isEditing ? 'LÆ°u thay Ä‘á»•i' : 'Táº¡o lá»‹ch há»c',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int?> _pickTime(int minutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return null;
    return picked.hour * 60 + picked.minute;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endTime <= _startTime) {
      _showMessage('Giá» káº¿t thÃºc pháº£i sau giá» báº¯t Ä‘áº§u.');
      return;
    }
    setState(() => _saving = true);
    final schedule = (widget.schedule ?? ScheduleModel.empty()).copyWith(
      subjectName: _subjectController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startTime: _startTime,
      endTime: _endTime,
      room: _roomController.text.trim(),
      teacher: _teacherController.text.trim(),
      note: _noteController.text.trim(),
      color: _color,
      repeatWeekly: _repeatWeekly,
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: _reminderMinutesBefore,
    );
    try {
      final actions = ref.read(scheduleActionsProvider);
      if (widget.schedule == null) {
        await actions.add(schedule);
      } else {
        await actions.update(schedule);
      }
      if (mounted) context.pop();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('XoÃ¡ lá»‹ch há»c?'),
        content: const Text(
          'MÃ´n há»c nÃ y sáº½ bá»‹ xoÃ¡ khá»i cloud vÃ  thiáº¿t bá»‹ Ä‘á»“ng bá»™.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huá»·'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('XoÃ¡'),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.schedule == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(scheduleActionsProvider).delete(widget.schedule!.id);
      if (mounted) context.pop();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.tileSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.glassStrokeSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChoice {
  const _ColorChoice(this.label, this.value);

  final String label;
  final int value;
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _ColorChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = Color(choice.value);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 104,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? color.withValues(alpha: colorScheme.isDark ? 0.20 : 0.14)
              : colorScheme.tileSurface,
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.76)
                : colorScheme.glassStrokeSubtle,
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: selected ? 0.22 : 0.10),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.white, 0.32)!],
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                choice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
