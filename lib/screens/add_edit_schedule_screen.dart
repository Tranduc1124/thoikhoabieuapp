import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
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

  static const _colors = [
    0xFF6A8DFF,
    0xFF87DCC0,
    0xFFFFB59D,
    0xFFC9B6FF,
    0xFFFF8FAB,
    0xFF9AD7FF,
    0xFFFFD166,
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa môn học' : 'Thêm môn học'),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Xoá',
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
                  title: 'Chi tiết lịch học',
                  subtitle: 'Thiết lập môn học, thời gian và nhắc nhở',
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Thông tin môn học',
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tên môn học',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Không để trống tên môn'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _teacherController,
                      decoration: const InputDecoration(
                        labelText: 'Giáo viên',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Thời gian',
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
                            label: 'Bắt đầu',
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
                            label: 'Kết thúc',
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
                  title: 'Địa điểm & ghi chú',
                  children: [
                    TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(
                        labelText: 'Phòng học',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Màu sắc',
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final value in _colors)
                          _ColorDot(
                            value: value,
                            selected: _color == value,
                            onTap: () => setState(() => _color = value),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Nhắc nhở',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _repeatWeekly,
                      onChanged: (value) =>
                          setState(() => _repeatWeekly = value),
                      title: const Text('Lặp lại hàng tuần'),
                      secondary: const Icon(Icons.repeat_rounded),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _reminderEnabled,
                      onChanged: (value) =>
                          setState(() => _reminderEnabled = value),
                      title: const Text('Nhắc trước giờ học'),
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                    ),
                    if (_reminderEnabled)
                      DropdownButtonFormField<int>(
                        initialValue: _reminderMinutesBefore,
                        decoration: const InputDecoration(
                          labelText: 'Nhắc trước',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: const [5, 10, 15, 30]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value phút'),
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
                  label: Text(isEditing ? 'Lưu thay đổi' : 'Tạo lịch học'),
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
      _showMessage('Giờ kết thúc phải sau giờ bắt đầu.');
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
        title: const Text('Xoá lịch học?'),
        content: const Text(
          'Môn học này sẽ bị xoá khỏi cloud và thiết bị đồng bộ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
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
          color: colorScheme.surface.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.10),
          ),
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

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(value);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: selected ? 50 : 44,
        height: selected ? 50 : 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white.withValues(alpha: 0.72),
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.26),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white)
            : null,
      ),
    );
  }
}
