import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_details_screen.dart';

class CreateEventScreen extends StatefulWidget {
  final bool returnCreatedEvent;

  const CreateEventScreen({super.key, this.returnCreatedEvent = false});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _linkFocus = FocusNode();

  bool _isSubmitting = false;
  String _eventType = 'Online'; // 'Online' or 'In person'
  File? _coverImage;

  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? _titleError;
  String? _dateError;
  String? _linkError;
  String? _locationError;

  static const List<String> _categoryKeys = [
    'community.workshop',
    'community.seminar',
    'community.hackathon',
    'community.competition',
    'community.career',
    'community.technology',
    'community.categoryOther',
  ];

  String get _formattedDate {
    if (_selectedDate == null) return '';
    final d = _selectedDate!;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayName = days[d.weekday - 1];
    final monthName = months[d.month - 1];
    final dateStr = '$dayName, $monthName ${d.day}';

    if (_selectedTime != null) {
      final h = _selectedTime!.hourOfPeriod == 0
          ? 12
          : _selectedTime!.hourOfPeriod;
      final m = _selectedTime!.minute.toString().padLeft(2, '0');
      final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      return '$dateStr · $h:$m $period';
    }
    return dateStr;
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      if (_titleError != null && _titleController.text.trim().isNotEmpty) {
        setState(() => _titleError = null);
      } else {
        setState(() {});
      }
    });
    _locationController.addListener(() {
      if (_locationError != null && _locationController.text.trim().isNotEmpty) {
        setState(() => _locationError = null);
      } else {
        setState(() {});
      }
    });
    _linkController.addListener(() {
      if (_linkError != null && _linkController.text.trim().isNotEmpty) {
        setState(() => _linkError = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _locationFocus.dispose();
    _linkFocus.dispose();
    super.dispose();
  }

  void _onBackPress() {
    final hasContent =
        _titleController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _linkController.text.trim().isNotEmpty ||
        _selectedDate != null ||
        _selectedCategory != null ||
        _coverImage != null;

    if (hasContent) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dialogBg = isDark ? const Color(0xFF1E2228) : Colors.white;
      final titleColor = isDark ? Colors.white : Colors.black87;
      final contentColor = isDark ? Colors.white70 : Colors.black54;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'community.discardDraft'.tr,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'community.discardMessage'.tr,
            style: TextStyle(color: contentColor, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'community.keepEditing'.tr,
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'community.discard'.tr,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialDate =
        _selectedDate ?? DateTime.now().add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    surface: Color(0xFF161616),
                    onSurface: Colors.white,
                  ),
                  dialogTheme: const DialogThemeData(
                    backgroundColor: Color(0xFF161616),
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
      if (!mounted) return;

      final initialTime = _selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
      final pickedTime = await _showCustomTimePicker(
        context,
        initialTime: initialTime,
      );
      if (pickedTime != null) {
        setState(() => _selectedTime = pickedTime);
      }
    }
  }

  void _submit() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Event name is required');
      AppNotificationBanner.showDanger(
        context: context,
        title: 'Validation Error',
        message: 'Event name is required.',
      );
      _titleFocus.requestFocus();
      return;
    }

    if (_selectedDate == null) {
      setState(() => _dateError = 'Date & time is required');
      AppNotificationBanner.showDanger(
        context: context,
        title: 'Validation Error',
        message: 'Date & time is required.',
      );
      return;
    }

    if (_eventType == 'Online') {
      final link = _linkController.text.trim();
      if (link.isEmpty) {
        setState(() => _linkError = 'Online event link is required');
        AppNotificationBanner.showDanger(
          context: context,
          title: 'Validation Error',
          message: 'Online event link is required.',
        );
        _linkFocus.requestFocus();
        return;
      }
    } else {
      final loc = _locationController.text.trim();
      if (loc.isEmpty) {
        setState(() => _locationError = 'Location is required');
        AppNotificationBanner.showDanger(
          context: context,
          title: 'Validation Error',
          message: 'Location is required.',
        );
        _locationFocus.requestFocus();
        return;
      }
    }

    setState(() => _isSubmitting = true);

    // Short UI feedback delay (local-first, no network)
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Build an EventModel from the form data
    final newEvent = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subtitle: _descController.text.trim().isNotEmpty
          ? _descController.text.trim().split('\n').first
          : '',
      organizerName: 'Me',
      eventType: _eventType,
      location: _eventType == 'In person'
          ? _locationController.text.trim()
          : '',
      onlineLink: _eventType == 'Online' ? _linkController.text.trim() : '',
      dateString: _formattedDate,
      timeString: '',
      description: _descController.text.trim(),
      category: _selectedCategory?.tr ?? '',
      imageUrl: '',
      coverImageFile: _coverImage,
      attendeesCount: 0,
    );

    // Register in controller so the Event list updates reactively
    final controller = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : Get.put(CommunityController());
    controller.createEvent(newEvent);

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    AppNotificationBanner.showSuccess(
      context: context,
      title: 'community.eventCreated'.tr,
      message: 'community.eventCreatedMsg'.tr,
    );

    if (widget.returnCreatedEvent) {
      Get.back(result: newEvent);
    } else {
      // Navigate to the freshly-created event's detail screen
      Get.off(() => EventDetailsScreen(event: newEvent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Strict Dark Theme based on instructions
    final bg = isDark ? Colors.black : Colors.white;
    final inputBg = isDark ? const Color(0xFF181818) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark
        ? const Color(0xFFA6A6A6)
        : const Color(0xFF666666);
    final cardBorder = isDark
        ? const Color(0xFF303030)
        : const Color(0xFFDDDDDD);
    final imagePlaceholderBg = isDark
        ? const Color(0xFF181818)
        : const Color(0xFFF0F2F5);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPress();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leadingWidth: 44,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 12),
            icon: Icon(Icons.close, color: textPrimary, size: 24),
            onPressed: _onBackPress,
          ),
          titleSpacing: 8,
          title: Text(
            'community.createEvent'.tr.isNotEmpty &&
                    'community.createEvent'.tr != 'community.createEvent'
                ? 'community.createEvent'.tr
                : 'Create Event',
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF222222)
                      : const Color(0xFFE0E0E0),
                  disabledForegroundColor: isDark
                      ? Colors.white30
                      : Colors.black38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Banner Image Area ─────────────────────────────────────────
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: imagePlaceholderBg,
                        border: Border(bottom: BorderSide(color: cardBorder)),
                      ),
                      child: Stack(
                        children: [
                          if (_coverImage != null)
                            Positioned.fill(
                              child: Image.file(_coverImage!, fit: BoxFit.cover),
                            )
                          else
                            GestureDetector(
                              onTap: _pickCoverImage,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: textMuted,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload cover image',
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _pickCoverImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black54 : Colors.white70,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: textPrimary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                if (_coverImage != null) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => _coverImage = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.black54
                                            : Colors.white70,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: textPrimary,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Event Type ──────────────────────────────────────────
                        _buildLabel('Event type', textMuted),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRadioButton('Online', 'Online', textPrimary),
                            const SizedBox(width: 24),
                            _buildRadioButton('In person', 'In person', textPrimary),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Event Name ──────────────────────────────────────────
                        _buildLabel('Event name*', textMuted),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          focusNode: _titleFocus,
                          maxLines: 1,
                          style: TextStyle(color: textPrimary, fontSize: 16),
                          decoration: _inputDeco(
                            cardBorder: cardBorder,
                            textPrimary: textPrimary,
                            inputBg: inputBg,
                            errorText: _titleError,
                            hintText: 'Event name',
                            textMuted: textMuted,
                          ),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _eventType == 'Online'
                              ? _linkFocus.requestFocus()
                              : _locationFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),

                        // ── Date and Time ───────────────────────────────────────
                        _buildLabel('Date & time*', textMuted),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: IgnorePointer(
                            child: TextField(
                              controller: TextEditingController(
                                text: _formattedDate,
                              ),
                              style: TextStyle(color: textPrimary, fontSize: 16),
                              decoration: _inputDeco(
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                inputBg: inputBg,
                                errorText: _dateError,
                                hintText: 'Select date and time',
                                textMuted: textMuted,
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: textMuted,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Dynamic Field (Location / Link) ─────────────────────
                        if (_eventType == 'Online') ...[
                          _buildLabel('Online event link*', textMuted),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _linkController,
                            focusNode: _linkFocus,
                            maxLines: 1,
                            style: TextStyle(color: textPrimary, fontSize: 16),
                            decoration: _inputDeco(
                              cardBorder: cardBorder,
                              textPrimary: textPrimary,
                              inputBg: inputBg,
                              errorText: _linkError,
                              hintText: 'e.g. https://meet.google.com/...',
                              textMuted: textMuted,
                              prefixIcon: Icon(
                                Icons.link_rounded,
                                color: textMuted,
                                size: 20,
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _descFocus.requestFocus(),
                          ),
                        ] else ...[
                          _buildLabel('Location*', textMuted),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _locationController,
                            focusNode: _locationFocus,
                            maxLines: 1,
                            style: TextStyle(color: textPrimary, fontSize: 16),
                            decoration: _inputDeco(
                              cardBorder: cardBorder,
                              textPrimary: textPrimary,
                              inputBg: inputBg,
                              errorText: _locationError,
                              hintText: '📍 Enter event location',
                              textMuted: textMuted,
                            ),
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _descFocus.requestFocus(),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // ── Description ─────────────────────────────────────────
                        _buildLabel('Description', textMuted),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          focusNode: _descFocus,
                          minLines: 4,
                          maxLines: 10,
                          maxLength: 5000,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          decoration: _inputDeco(
                            cardBorder: cardBorder,
                            textPrimary: textPrimary,
                            inputBg: inputBg,
                            hintText: 'Tell people about your event',
                            textMuted: textMuted,
                          ),
                          textInputAction: TextInputAction.done,
                        ),

                        const SizedBox(height: 24),

                        // ── Category (Preserved GenLink Feature) ────────────────
                        _buildLabel(
                          'community.category'.tr.isNotEmpty &&
                                  'community.category'.tr !=
                                      'community.category'
                              ? 'community.category'.tr
                              : 'Category (Optional)',
                          textMuted,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categoryKeys.map((key) {
                            final isSelected = _selectedCategory == key;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedCategory = isSelected ? null : key;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? textPrimary : inputBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : cardBorder,
                                  ),
                                ),
                                child: Text(
                                  key.tr,
                                  style: TextStyle(
                                    color: isSelected ? bg : textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildRadioButton(String displayTitle, String rawValue, Color textPrimary) {
    final isSelected = _eventType == rawValue;
    return GestureDetector(
      onTap: () {
        if (_eventType != rawValue) {
          setState(() {
            _eventType = rawValue;
            _linkError = null;
            _locationError = null;
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: textPrimary,
                width: isSelected ? 5.5 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(displayTitle, style: TextStyle(color: textPrimary, fontSize: 15)),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    required Color cardBorder,
    required Color textPrimary,
    required Color inputBg,
    String? hintText,
    Color? textMuted,
    String? errorText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: inputBg,
      hintText: hintText,
      hintStyle: textMuted != null
          ? TextStyle(color: textMuted, fontSize: 16)
          : null,
      prefixIcon: prefixIcon,
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontSize: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: errorText != null ? Colors.redAccent : cardBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: errorText != null ? Colors.redAccent : textPrimary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      counterStyle: const TextStyle(fontSize: 13), // for maxLength counter
    );
  }
}

/// Opens the modern custom GenLink time picker modal bottom sheet
Future<TimeOfDay?> _showCustomTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _GenLinkTimePickerSheet(initialTime: initialTime),
  );
}

/// Custom GenLink Time Picker Modal Sheet with strict black/white/gray theme
class _GenLinkTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;

  const _GenLinkTimePickerSheet({required this.initialTime});

  @override
  State<_GenLinkTimePickerSheet> createState() =>
      _GenLinkTimePickerSheetState();
}

class _GenLinkTimePickerSheetState extends State<_GenLinkTimePickerSheet> {
  late int _selectedHour12; // 1 to 12
  late int _selectedMinute; // 0 to 59
  late DayPeriod _selectedPeriod; // AM or PM

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hourOfPeriod;
    _selectedHour12 = h == 0 ? 12 : h;
    _selectedMinute = widget.initialTime.minute;
    _selectedPeriod = widget.initialTime.period;
  }

  String get _formattedSelectedTime {
    final mStr = _selectedMinute.toString().padLeft(2, '0');
    final periodStr = _selectedPeriod == DayPeriod.am ? 'AM' : 'PM';
    return '$_selectedHour12:$mStr $periodStr';
  }

  TimeOfDay get _resultingTimeOfDay {
    int hour24;
    if (_selectedPeriod == DayPeriod.am) {
      hour24 = _selectedHour12 == 12 ? 0 : _selectedHour12;
    } else {
      hour24 = _selectedHour12 == 12 ? 12 : _selectedHour12 + 12;
    }
    return TimeOfDay(hour: hour24, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141414) : Colors.white;
    final border = isDark ? const Color(0xFF303030) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final surfaceUnselected = isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6);
    final displayBoxBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB);

    final selectTimeTitle = 'community.selectTime'.tr.isNotEmpty &&
            'community.selectTime'.tr != 'community.selectTime'
        ? 'community.selectTime'.tr
        : 'Select time';
    final hourLabel = 'community.hour'.tr.isNotEmpty &&
            'community.hour'.tr != 'community.hour'
        ? 'community.hour'.tr
        : 'Hour';
    final minuteLabel = 'community.minute'.tr.isNotEmpty &&
            'community.minute'.tr != 'community.minute'
        ? 'community.minute'.tr
        : 'Minute';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            Text(
              selectTimeTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Prominent Selected Time Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: displayBoxBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 0.8),
              ),
              child: Center(
                child: Text(
                  _formattedSelectedTime,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // AM / PM Segmented Control Toggle
            Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: surfaceUnselected,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPeriod = DayPeriod.am),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _selectedPeriod == DayPeriod.am
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'AM',
                          style: TextStyle(
                            color: _selectedPeriod == DayPeriod.am
                                ? (isDark ? Colors.black : Colors.white)
                                : textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPeriod = DayPeriod.pm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _selectedPeriod == DayPeriod.pm
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'PM',
                          style: TextStyle(
                            color: _selectedPeriod == DayPeriod.pm
                                ? (isDark ? Colors.black : Colors.white)
                                : textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Hours Selection (1 to 12)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hourLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(12, (index) {
                  final hour = index + 1;
                  final isSelected = _selectedHour12 == hour;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedHour12 = hour),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : surfaceUnselected,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : border,
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$hour',
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Minutes Selection (00 to 55 in 5 min increments)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                minuteLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: () {
                  final minuteList = [
                    0,
                    5,
                    10,
                    15,
                    20,
                    25,
                    30,
                    35,
                    40,
                    45,
                    50,
                    55,
                  ];
                  if (!minuteList.contains(_selectedMinute)) {
                    minuteList.add(_selectedMinute);
                    minuteList.sort();
                  }
                  return minuteList.map((m) {
                    final isSelected = _selectedMinute == m;
                    final mStr = m.toString().padLeft(2, '0');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMinute = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 46,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : surfaceUnselected,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : border,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            mStr,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList();
                }(),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Actions: Cancel and OK
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: border),
                        ),
                      ),
                      child: Text(
                        'common.cancel'.tr.isNotEmpty &&
                                'common.cancel'.tr != 'common.cancel'
                            ? 'common.cancel'.tr
                            : 'Cancel',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, _resultingTimeOfDay),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
