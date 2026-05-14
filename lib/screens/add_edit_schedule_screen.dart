import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_model.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../services/firebase_error_translator.dart';
import '../theme/app_colors.dart';
import '../widgets/app_popup.dart';
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
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

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
    _locationController.text = initial.locationAddress;
    _latitudeController.text = initial.latitude?.toString() ?? '';
    _longitudeController.text = initial.longitude?.toString() ?? '';
    _locationController.addListener(_refreshLocationPreview);
    _latitudeController.addListener(_refreshLocationPreview);
    _longitudeController.addListener(_refreshLocationPreview);
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
    _locationController.removeListener(_refreshLocationPreview);
    _latitudeController.removeListener(_refreshLocationPreview);
    _longitudeController.removeListener(_refreshLocationPreview);
    _subjectController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _refreshLocationPreview() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;
    final reminderOptions = {5, 10, 15, 30, 60, _reminderMinutesBefore}.toList()
      ..sort();
    final previewColor = Color(_color);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa môn học' : 'Thêm môn học'),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
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
                Hero(
                  tag: 'schedule-hero-${widget.schedule?.id ?? 'new'}',
                  child: GlassCard(
                    radius: 34,
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              colors: [
                                previewColor,
                                Color.lerp(previewColor, Colors.white, 0.28)!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: previewColor.withValues(alpha: 0.26),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? 'Cập nhật lớp học của bạn'
                                    : 'Tạo buổi học mới với nhịp iOS premium',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Thiết lập thời gian, màu sắc, nhắc nhở và vị trí lớp học trong một flow gọn hơn.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const SectionHeader(
                  title: 'Chi tiết lịch học',
                  subtitle:
                      'Điền thông tin quan trọng để app theo dõi môn học chính xác.',
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Thông tin môn học',
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Tên môn học',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Không được để trống tên môn.'
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
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ / mô tả vị trí',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: Icon(Icons.pin_drop_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              prefixIcon: Icon(Icons.explore_outlined),
                            ),
                          ),
                        ),
                      ],
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
                    if (_locationController.text.trim().isNotEmpty ||
                        _latitudeController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _MapPreview(
                        address: _locationController.text.trim(),
                        latitude: double.tryParse(
                          _latitudeController.text.trim(),
                        ),
                        longitude: double.tryParse(
                          _longitudeController.text.trim(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Màu sắc',
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
      await showAppPopup(
        context,
        title: 'Thời gian chưa hợp lệ',
        message: 'Giờ kết thúc phải sau giờ bắt đầu.',
        type: AppPopupType.error,
      );
      return;
    }
    setState(() => _saving = true);
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final locationService = ref.read(classroomLocationServiceProvider);
    final schedule = (widget.schedule ?? ScheduleModel.empty()).copyWith(
      subjectName: _subjectController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startTime: _startTime,
      endTime: _endTime,
      room: _roomController.text.trim(),
      teacher: _teacherController.text.trim(),
      note: _noteController.text.trim(),
      color: _color,
      locationAddress: _locationController.text.trim(),
      latitude: latitude,
      longitude: longitude,
      appleMapsUrl:
          _locationController.text.trim().isEmpty &&
              latitude == null &&
              longitude == null
          ? null
          : locationService?.buildAppleMapsUrl(
              address: _locationController.text.trim(),
              latitude: latitude,
              longitude: longitude,
            ),
      googleMapsUrl:
          _locationController.text.trim().isEmpty &&
              latitude == null &&
              longitude == null
          ? null
          : locationService?.buildGoogleMapsUrl(
              address: _locationController.text.trim(),
              latitude: latitude,
              longitude: longitude,
            ),
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
      if (!mounted) return;
      await showAppPopup(
        context,
        title: 'Không thể lưu lịch học',
        message: FirebaseErrorTranslator.readable(error),
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch học?'),
        content: const Text(
          'Môn học này sẽ bị xóa khỏi cloud, widget và hệ thống thông báo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
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
      if (!mounted) return;
      await showAppPopup(
        context,
        title: 'Không thể xóa lịch học',
        message: FirebaseErrorTranslator.readable(error),
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
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
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends ConsumerWidget {
  const _MapPreview({required this.address, this.latitude, this.longitude});

  final String address;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(classroomLocationServiceProvider);
    if (service == null) return const SizedBox.shrink();

    final apple = service.buildAppleMapsUrl(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    final google = service.buildGoogleMapsUrl(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).colorScheme.tileSurface,
        border: Border.all(
          color: Theme.of(context).colorScheme.glassStrokeSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview vị trí lớp học',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            address.isEmpty ? 'Sử dụng toạ độ để mở bản đồ.' : address,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => service.openAppleMapsUrl(apple),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Apple Maps'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => service.openGoogleMapsUrl(google),
                icon: const Icon(Icons.travel_explore_rounded),
                label: const Text('Google Maps'),
              ),
            ],
          ),
        ],
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
