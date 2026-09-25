import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_details_screen.dart';

class CreateEventScreen extends StatefulWidget {
  final bool returnCreatedEvent;
  final EventModel? eventToEdit;

  const CreateEventScreen({
    super.key,
    this.returnCreatedEvent = false,
    this.eventToEdit,
  });

  bool get isEditing => eventToEdit != null;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _attendeeLimitController =
      TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _linkFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _attendeeLimitFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  bool _isSubmitting = false;

  // Backend EventMode: 'ONLINE' vs 'IN_PERSON' (Default 'Online' for tests)
  String _eventType = 'Online';

  // Cover image
  File? _coverImage;
  final bool _isUploadingImage = false;

  // Category
  String? _selectedCategory;

  // Schedule
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  // Pricing
  bool _isPaid = false;
  String _selectedCurrency = 'USD'; // Backend Currency: 'USD' or 'KHR'
  String _selectedStatus = 'PUBLISHED';

  static const List<String> _eventStatuses = [
    'DRAFT',
    'PUBLISHED',
    'CANCELLED',
    'COMPLETED',
  ];

  // Errors
  String? _titleError;
  String? _dateError;
  String? _timeError;
  String? _locationError;
  String? _linkError;
  String? _priceError;

  static const List<String> _categories = [
    'Technology',
    'Design',
    'Business',
    'Career',
    'Education',
    'Social',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.eventToEdit;
    if (edit != null) {
      _titleController.text = edit.title;
      _descController.text = edit.description;
      _eventType = edit.isOnline ? 'Online' : 'In person';
      _selectedCategory = edit.category.isNotEmpty ? edit.category : null;
      _startDate = edit.startDateTime;
      if (edit.startDateTime != null) {
        _startTime = TimeOfDay(
          hour: edit.startDateTime!.hour,
          minute: edit.startDateTime!.minute,
        );
      }
      _endDate = edit.endDateTime;
      if (edit.endDateTime != null) {
        _endTime = TimeOfDay(
          hour: edit.endDateTime!.hour,
          minute: edit.endDateTime!.minute,
        );
      }
      if (edit.isOnline) {
        // The backend's protected field is the only source of truth for an
        // existing meeting URL. Legacy `onlineLink` values must not be
        // reintroduced into an edit request or displayed as a join link.
        _linkController.text = edit.meetingUrl ?? '';
      } else {
        _locationController.text = edit.locationName ?? edit.location;
      }
      _isPaid = edit.isPaid;
      _selectedStatus = _eventStatuses.contains(edit.normalizedStatus)
          ? edit.normalizedStatus
          : 'PUBLISHED';
      if (edit.currency != null && edit.currency!.isNotEmpty) {
        _selectedCurrency = edit.currency!;
      }
      if (edit.price != null && edit.price! > 0) {
        _priceController.text = edit.price! % 1 == 0
            ? edit.price!.toInt().toString()
            : edit.price!.toString();
      }
      if (edit.attendeeLimit != null && edit.attendeeLimit! > 0) {
        _attendeeLimitController.text = edit.attendeeLimit.toString();
      }
      _coverImage = edit.coverImageFile;
    }

    _titleController.addListener(() {
      if (_titleError != null) setState(() => _titleError = null);
    });
    _locationController.addListener(() {
      if (_locationError != null) setState(() => _locationError = null);
    });
    _linkController.addListener(() {
      if (_linkError != null) setState(() => _linkError = null);
    });
    _priceController.addListener(() {
      if (_priceError != null) setState(() => _priceError = null);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _priceController.dispose();
    _attendeeLimitController.dispose();

    _titleFocus.dispose();
    _descFocus.dispose();
    _locationFocus.dispose();
    _linkFocus.dispose();
    _priceFocus.dispose();
    _attendeeLimitFocus.dispose();

    _scrollController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.eventToEdit != null;

  DateTime? get _calculatedStartDateTime {
    if (_startDate == null) return null;
    final time = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      time.hour,
      time.minute,
    );
  }

  DateTime? get _calculatedEndDateTime {
    if (_endDate == null) return null;
    final time = _endTime ?? const TimeOfDay(hour: 11, minute: 0);
    return DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
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
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}, ${dt.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get _formattedScheduleDisplay {
    if (_startDate == null) return '';
    final dateStr = _formatDate(_startDate);
    final timeStr = _startTime != null ? ' at ${_formatTime(_startTime)}' : '';
    return '$dateStr$timeStr';
  }

  void _onBackPress() {
    final hasContent =
        _titleController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _linkController.text.trim().isNotEmpty ||
        _priceController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _coverImage != null;

    if (hasContent) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dialogBg = isDark ? const Color(0xFF1E1E22) : Colors.white;
      final titleColor = isDark ? Colors.white : AppColors.lightTextPrimary;
      final contentColor = isDark
          ? Colors.white70
          : AppColors.lightTextSecondary;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDark
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  )
                : BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
          ),
          title: Text(
            'community.discardDraft'.tr.isNotEmpty &&
                    'community.discardDraft'.tr != 'community.discardDraft'
                ? 'community.discardDraft'.tr
                : 'Discard Event?',
            style: TextStyle(
              color: titleColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'community.discardMessage'.tr.isNotEmpty &&
                    'community.discardMessage'.tr != 'community.discardMessage'
                ? 'community.discardMessage'.tr
                : 'You have unsaved changes. Are you sure you want to discard this event?',
            style: TextStyle(color: contentColor, fontSize: 14, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'community.keepEditing'.tr.isNotEmpty &&
                        'community.keepEditing'.tr != 'community.keepEditing'
                    ? 'community.keepEditing'.tr
                    : 'Keep Editing',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'community.discard'.tr.isNotEmpty &&
                        'community.discard'.tr != 'community.discard'
                    ? 'community.discard'.tr
                    : 'Discard',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: 'Error',
          message: 'Failed to select image.',
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final initialDate =
        _startDate ?? DateTime.now().add(const Duration(days: 1));
    final pickedDate = await _showGenLinkDatePicker(
      context,
      initialDate: initialDate,
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        _endDate = pickedDate;
        _dateError = null;
      });

      if (!mounted) return;

      final initialTime = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
      final pickedTime = await _showGenLinkTimePicker(
        context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        setState(() {
          _startTime = pickedTime;
          _endTime = TimeOfDay(
            hour: (pickedTime.hour + 2) % 24,
            minute: pickedTime.minute,
          );
          _timeError = null;
          _validateStartEndTime();
        });
      }
    }
  }

  Future<void> _pickStartDate() async {
    final initial = _startDate ?? DateTime.now().add(const Duration(days: 1));
    final picked = await _showGenLinkDatePicker(
      context,
      initialDate: initial,
      title:
          'community.selectDate'.tr.isNotEmpty &&
              'community.selectDate'.tr != 'community.selectDate'
          ? 'community.selectDate'.tr
          : 'Select date',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate == null || _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
        _dateError = null;
        _validateStartEndTime();
      });
    }
  }

  Future<void> _pickStartTime() async {
    final initial = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await _showGenLinkTimePicker(
      context,
      initialTime: initial,
      title:
          'community.selectTime'.tr.isNotEmpty &&
              'community.selectTime'.tr != 'community.selectTime'
          ? 'community.selectTime'.tr
          : 'Select time',
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _endTime ??= TimeOfDay(
          hour: (picked.hour + 2) % 24,
          minute: picked.minute,
        );
        _validateStartEndTime();
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial =
        _endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 1));
    final picked = await _showGenLinkDatePicker(
      context,
      initialDate: initial,
      title: 'End date',
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _validateStartEndTime();
      });
    }
  }

  Future<void> _pickEndTime() async {
    final initial =
        _endTime ??
        (_startTime != null
            ? TimeOfDay(
                hour: (_startTime!.hour + 2) % 24,
                minute: _startTime!.minute,
              )
            : const TimeOfDay(hour: 11, minute: 0));
    final picked = await _showGenLinkTimePicker(
      context,
      initialTime: initial,
      title: 'End time',
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _validateStartEndTime();
      });
    }
  }

  void _validateStartEndTime() {
    if (_startDate == null ||
        _startTime == null ||
        _endDate == null ||
        _endTime == null) {
      _timeError = null;
      return;
    }
    final start = _calculatedStartDateTime!;
    final end = _calculatedEndDateTime!;
    if (!end.isAfter(start)) {
      _timeError = 'End time must be after start time';
    } else {
      _timeError = null;
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'DRAFT':
        return 'community.eventDraft'.tr;
      case 'PUBLISHED':
        return 'community.published'.tr;
      case 'CANCELLED':
        return 'community.eventCancelled'.tr;
      case 'COMPLETED':
        return 'community.eventCompleted'.tr;
      default:
        return value;
    }
  }

  void _showStatusBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161618) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final tileActive = isDark
        ? const Color(0xFF222226)
        : const Color(0xFFF3F4F6);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'community.eventStatus'.tr,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final status in _eventStatuses)
              ListTile(
                title: Text(
                  _statusLabel(status),
                  style: TextStyle(color: textPrimary),
                ),
                selected: status == _selectedStatus,
                selectedTileColor: tileActive,
                trailing: status == _selectedStatus
                    ? Icon(Icons.check_rounded, color: textPrimary)
                    : null,
                onTap: () {
                  setState(() => _selectedStatus = status);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161618) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final border = isDark ? const Color(0xFF2E2E32) : const Color(0xFFE5E7EB);
    final tileActive = isDark
        ? const Color(0xFF222226)
        : const Color(0xFFF3F4F6);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'community.category'.tr.isNotEmpty &&
                              'community.category'.tr != 'community.category'
                          ? 'community.category'.tr
                          : 'Select Category',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textPrimary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        color: isSelected ? tileActive : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIconData(cat),
                              size: 20,
                              color: isDark ? Colors.white70 : textSecondary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _getCategoryLabel(cat),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                color: isDark ? Colors.white : Colors.black,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIconData(String cat) {
    switch (cat.toLowerCase()) {
      case 'technology':
        return Icons.computer_outlined;
      case 'design':
      case 'arts':
      case 'art':
        return Icons.palette_outlined;
      case 'business':
        return Icons.business_center_outlined;
      case 'career':
        return Icons.work_outline_rounded;
      case 'education':
        return Icons.school_outlined;
      case 'workshop':
        return Icons.build_outlined;
      case 'competition':
        return Icons.emoji_events_outlined;
      case 'sports':
      case 'sport':
        return Icons.sports_soccer_outlined;
      case 'social':
        return Icons.people_outline_rounded;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'seminar':
        return Icons.groups_outlined;
      case 'hackathon':
        return Icons.terminal_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  String _getCategoryLabel(String cat) {
    final trKey = 'community.category${cat.capitalizeFirst}';
    final translated = trKey.tr;
    if (translated.isNotEmpty && translated != trKey) {
      return translated;
    }
    return cat;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _titleError = null;
      _dateError = null;
      _timeError = null;
      _locationError = null;
      _linkError = null;
      _priceError = null;
    });

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

    if (title.length > 180) {
      setState(() => _titleError = 'Title cannot exceed 180 characters');
      AppNotificationBanner.showDanger(
        context: context,
        title: 'Validation Error',
        message: 'Title cannot exceed 180 characters.',
      );
      _titleFocus.requestFocus();
      return;
    }

    if (_startDate == null) {
      setState(() => _dateError = 'Date & time is required');
      AppNotificationBanner.showDanger(
        context: context,
        title: 'Validation Error',
        message: 'Date & time is required.',
      );
      return;
    }

    final startDateTime = _calculatedStartDateTime!;
    final endDateTime =
        _calculatedEndDateTime ?? startDateTime.add(const Duration(hours: 2));

    if (!endDateTime.isAfter(startDateTime)) {
      setState(() => _timeError = 'End time must be after start time');
      AppNotificationBanner.showDanger(
        context: context,
        title: 'Validation Error',
        message: 'End time must be after start time.',
      );
      return;
    }

    final isOnline = _eventType == 'Online';
    final location = _locationController.text.trim();
    final link = _linkController.text.trim();

    if (isOnline) {
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
      final uri = Uri.tryParse(link);
      if (uri == null ||
          (!uri.isScheme('http') && !uri.isScheme('https')) ||
          uri.host.isEmpty) {
        setState(
          () => _linkError = 'Meeting URL must start with http:// or https://',
        );
        AppNotificationBanner.showDanger(
          context: context,
          title: 'Validation Error',
          message: 'Meeting URL must start with http:// or https://',
        );
        _linkFocus.requestFocus();
        return;
      }
    } else {
      if (location.isEmpty) {
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

    double? parsedPrice;
    if (_isPaid) {
      final priceText = _priceController.text.trim();
      if (priceText.isEmpty) {
        setState(() => _priceError = 'Price is required for paid events');
        AppNotificationBanner.showDanger(
          context: context,
          title: 'Validation Error',
          message: 'Price is required for paid events.',
        );
        _priceFocus.requestFocus();
        return;
      }
      parsedPrice = double.tryParse(priceText);
      if (parsedPrice == null || parsedPrice <= 0) {
        setState(() => _priceError = 'Price must be greater than 0');
        AppNotificationBanner.showDanger(
          context: context,
          title: 'Validation Error',
          message: 'Price must be greater than 0.',
        );
        _priceFocus.requestFocus();
        return;
      }
    }

    int? attendeeLimit;
    if (_attendeeLimitController.text.trim().isNotEmpty) {
      attendeeLimit = int.tryParse(_attendeeLimitController.text.trim());
    }

    setState(() => _isSubmitting = true);

    try {
      final request = EventCreateRequest(
        title: title,
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        category: _selectedCategory,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        mode: isOnline ? 'ONLINE' : 'IN_PERSON',
        meetingUrl: isOnline ? link : null,
        locationName: isOnline ? null : location,
        attendeeLimit: attendeeLimit,
        paid: _isPaid,
        price: _isPaid ? parsedPrice : null,
        currency: _isPaid ? _selectedCurrency : null,
        status: _selectedStatus,
      );

      final controller = Get.isRegistered<CommunityController>()
          ? Get.find<CommunityController>()
          : Get.put(CommunityController());

      final isEditing = widget.eventToEdit != null;
      final EventModel resultEvent;
      if (isEditing) {
        resultEvent = await controller.updateEvent(
          widget.eventToEdit!.id,
          request,
          coverImageFile: _coverImage,
        );
      } else {
        resultEvent = await controller.createEvent(
          request,
          coverImageFile: _coverImage,
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppNotificationBanner.showSuccess(
        context: context,
        title: isEditing
            ? ('community.eventUpdated'.tr.isNotEmpty &&
                      'community.eventUpdated'.tr != 'community.eventUpdated'
                  ? 'community.eventUpdated'.tr
                  : 'Event Updated')
            : ('community.eventCreated'.tr.isNotEmpty &&
                      'community.eventCreated'.tr != 'community.eventCreated'
                  ? 'community.eventCreated'.tr
                  : 'Event Created'),
        message: isEditing
            ? ('community.eventUpdatedMsg'.tr.isNotEmpty &&
                      'community.eventUpdatedMsg'.tr !=
                          'community.eventUpdatedMsg'
                  ? 'community.eventUpdatedMsg'.tr
                  : 'Your event has been updated successfully.')
            : ('community.eventCreatedMsg'.tr.isNotEmpty &&
                      'community.eventCreatedMsg'.tr !=
                          'community.eventCreatedMsg'
                  ? 'community.eventCreatedMsg'.tr
                  : 'Your event has been published successfully.'),
      );

      if (widget.returnCreatedEvent || isEditing) {
        Get.back(result: resultEvent);
      } else {
        Get.off(() => EventDetailsScreen(event: resultEvent));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final errorMsg = e is AppError
          ? e.message
          : (isEditing
                ? 'Failed to update event. Please check your connection and try again.'
                : 'Failed to create event. Please check your connection and try again.');

      AppNotificationBanner.showDanger(
        context: context,
        title: 'Error',
        message: errorMsg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F0F11) : Colors.white;
    final surface = isDark ? const Color(0xFF161619) : const Color(0xFFF9FAFB);
    final cardBorder = isDark
        ? const Color(0xFF26262B)
        : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textMuted = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final primaryBtnBg = isDark ? Colors.white : Colors.black;
    final primaryBtnFg = isDark ? Colors.black : Colors.white;

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
          scrolledUnderElevation: 0,
          leadingWidth: 44,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 12),
            icon: Icon(Icons.close, color: textPrimary, size: 22),
            onPressed: _onBackPress,
          ),
          title: Text(
            widget.eventToEdit != null
                ? ('community.editEvent'.tr.isNotEmpty &&
                          'community.editEvent'.tr != 'community.editEvent'
                      ? 'community.editEvent'.tr
                      : 'Edit Event')
                : ('community.createEvent'.tr.isNotEmpty &&
                          'community.createEvent'.tr != 'community.createEvent'
                      ? 'community.createEvent'.tr
                      : 'Create Event'),
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBtnBg,
                  foregroundColor: primaryBtnFg,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF2A2A2E)
                      : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDark
                      ? Colors.white30
                      : Colors.black38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryBtnFg,
                        ),
                      )
                    : Text(
                        widget.eventToEdit != null ? 'Save Changes' : 'Create',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. COVER IMAGE ───────────────────────────────────────────
                _buildSectionHeader(
                  'community.coverImage'.tr.isNotEmpty &&
                          'community.coverImage'.tr != 'community.coverImage'
                      ? 'community.coverImage'.tr
                      : 'EVENT COVER PHOTO',
                  textMuted,
                ),
                const SizedBox(height: 8),
                _buildCoverImageSection(
                  isDark,
                  surface,
                  cardBorder,
                  textPrimary,
                  textMuted,
                ),

                const SizedBox(height: 24),

                // ── 2. GENERAL INFO ──────────────────────────────────────────
                _buildSectionHeader(
                  'community.eventDetails'.tr.isNotEmpty &&
                          'community.eventDetails'.tr !=
                              'community.eventDetails'
                      ? 'community.eventDetails'.tr
                      : 'EVENT DETAILS',
                  textMuted,
                ),
                const SizedBox(height: 12),

                // Title
                _buildFieldLabel('Event name*', textPrimary),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  maxLength: 180,
                  maxLines: 1,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: _inputDecoration(
                    hintText: 'Event name',
                    errorText: _titleError,
                    isDark: isDark,
                    surface: surface,
                    border: cardBorder,
                    textMuted: textMuted,
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Description
                _buildFieldLabel(
                  'community.eventDescription'.tr.isNotEmpty &&
                          'community.eventDescription'.tr !=
                              'community.eventDescription'
                      ? 'community.eventDescription'.tr
                      : 'Description',
                  textPrimary,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  focusNode: _descFocus,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 5000,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: _inputDecoration(
                    hintText: 'Tell people about your event',
                    isDark: isDark,
                    surface: surface,
                    border: cardBorder,
                    textMuted: textMuted,
                  ),
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 16),

                // Category Selector
                _buildFieldLabel(
                  'community.category'.tr.isNotEmpty &&
                          'community.category'.tr != 'community.category'
                      ? 'community.category'.tr
                      : 'Category',
                  textPrimary,
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showCategoryBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _selectedCategory != null
                                    ? _getCategoryIconData(_selectedCategory!)
                                    : Icons.category_outlined,
                                color: _selectedCategory != null
                                    ? (isDark ? Colors.white : Colors.black)
                                    : textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedCategory != null
                                      ? _getCategoryLabel(_selectedCategory!)
                                      : ('community.selectCategory'
                                                    .tr
                                                    .isNotEmpty &&
                                                'community.selectCategory'.tr !=
                                                    'community.selectCategory'
                                            ? 'community.selectCategory'.tr
                                            : 'Select Category'),
                                  style: TextStyle(
                                    color: _selectedCategory != null
                                        ? textPrimary
                                        : textMuted,
                                    fontSize: 15,
                                    fontWeight: _selectedCategory != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: textMuted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildFieldLabel('community.eventStatus'.tr, textPrimary),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showStatusBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusLabel(_selectedStatus),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: textMuted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── 3. DATE & TIME ───────────────────────────────────────────
                _buildSectionHeader('Date & time*', textMuted),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _pickDate,
                  child: IgnorePointer(
                    child: TextField(
                      controller: TextEditingController(
                        text: _formattedScheduleDisplay,
                      ),
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      decoration: _inputDecoration(
                        hintText:
                            'community.selectDateAndTime'.tr.isNotEmpty &&
                                'community.selectDateAndTime'.tr !=
                                    'community.selectDateAndTime'
                            ? 'community.selectDateAndTime'.tr
                            : 'Select date and time',
                        errorText: _dateError,
                        isDark: isDark,
                        surface: surface,
                        border: cardBorder,
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

                if (_startDate != null) ...[
                  const SizedBox(height: 10),
                  _buildScheduleChips(
                    isDark,
                    surface,
                    cardBorder,
                    textPrimary,
                    textMuted,
                  ),
                ],

                if (_timeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _timeError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── 4. EVENT TYPE ───────────────────────────────────────
                _buildSectionHeader(
                  'community.eventType'.tr.isNotEmpty &&
                          'community.eventType'.tr != 'community.eventType'
                      ? 'community.eventType'.tr
                      : 'EVENT TYPE',
                  textMuted,
                ),
                const SizedBox(height: 12),

                _buildSegmentedEventType(
                  isDark,
                  surface,
                  cardBorder,
                  textPrimary,
                  textMuted,
                ),

                const SizedBox(height: 16),

                // Location / Meeting URL depending on Event Type
                if (_eventType == 'In person') ...[
                  Row(children: [_buildFieldLabel('Location*', textPrimary)]),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _locationController,
                    focusNode: _locationFocus,
                    maxLines: 1,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: _inputDecoration(
                      hintText: '📍 Enter event location',
                      errorText: _locationError,
                      isDark: isDark,
                      surface: surface,
                      border: cardBorder,
                      textMuted: textMuted,
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: textMuted,
                        size: 20,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'community.locationHelper'.tr.isNotEmpty &&
                            'community.locationHelper'.tr !=
                                'community.locationHelper'
                        ? 'community.locationHelper'.tr
                        : 'Specify venue, building, room or address for in-person attendees.',
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                ] else ...[
                  _buildFieldLabel('Online event link*', textPrimary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _linkController,
                    focusNode: _linkFocus,
                    maxLines: 1,
                    keyboardType: TextInputType.url,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: _inputDecoration(
                      hintText: 'e.g. https://meet.google.com/...',
                      errorText: _linkError,
                      isDark: isDark,
                      surface: surface,
                      border: cardBorder,
                      textMuted: textMuted,
                      prefixIcon: Icon(
                        Icons.link_rounded,
                        color: textMuted,
                        size: 20,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'community.onlineLinkHelper'.tr.isNotEmpty &&
                            'community.onlineLinkHelper'.tr !=
                                'community.onlineLinkHelper'
                        ? 'community.onlineLinkHelper'.tr
                        : 'Provide a valid meeting link (Google Meet, Zoom, MS Teams, etc.).',
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 24),

                // ── 5. TICKETING & CAPACITY ──────────────────────────────
                _buildSectionHeader(
                  'community.ticketing'.tr.isNotEmpty &&
                          'community.ticketing'.tr != 'community.ticketing'
                      ? 'community.ticketing'.tr
                      : 'TICKETING & CAPACITY',
                  textMuted,
                ),
                const SizedBox(height: 12),

                // Paid toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _isPaid
                                  ? Icons.monetization_on
                                  : Icons.money_off_outlined,
                              color: _isPaid
                                  ? (isDark ? Colors.white : Colors.black)
                                  : textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'community.paidEvent'.tr.isNotEmpty &&
                                            'community.paidEvent'.tr !=
                                                'community.paidEvent'
                                        ? 'community.paidEvent'.tr
                                        : 'Paid Event',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'community.paidEventDesc'.tr.isNotEmpty &&
                                            'community.paidEventDesc'.tr !=
                                                'community.paidEventDesc'
                                        ? 'community.paidEventDesc'.tr
                                        : 'Require ticket purchase to attend',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: _isPaid,
                        onChanged: (val) {
                          setState(() {
                            _isPaid = val;
                            if (!val) {
                              _priceError = null;
                              _priceController.clear();
                            }
                          });
                        },
                        activeThumbColor: isDark ? Colors.white : Colors.black,
                        activeTrackColor: isDark
                            ? Colors.white38
                            : Colors.black26,
                      ),
                    ],
                  ),
                ),

                // Price and Currency if paid
                if (_isPaid) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(
                              'community.price'.tr.isNotEmpty &&
                                      'community.price'.tr != 'community.price'
                                  ? '${'community.price'.tr}*'
                                  : 'Price*',
                              textPrimary,
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _priceController,
                              focusNode: _priceFocus,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                              ),
                              decoration: _inputDecoration(
                                hintText: '0.00',
                                errorText: _priceError,
                                isDark: isDark,
                                surface: surface,
                                border: cardBorder,
                                textMuted: textMuted,
                                prefixIcon: Icon(
                                  Icons.attach_money,
                                  color: textMuted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(
                              'community.currency'.tr.isNotEmpty &&
                                      'community.currency'.tr !=
                                          'community.currency'
                                  ? 'community.currency'.tr
                                  : 'Currency',
                              textPrimary,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedCurrency = 'USD',
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedCurrency == 'USD'
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'USD',
                                          style: TextStyle(
                                            color: _selectedCurrency == 'USD'
                                                ? (isDark
                                                      ? Colors.black
                                                      : Colors.white)
                                                : textMuted,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedCurrency = 'KHR',
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedCurrency == 'KHR'
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'KHR',
                                          style: TextStyle(
                                            color: _selectedCurrency == 'KHR'
                                                ? (isDark
                                                      ? Colors.black
                                                      : Colors.white)
                                                : textMuted,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'community.freeEventNotice'.tr.isNotEmpty &&
                                    'community.freeEventNotice'.tr !=
                                        'community.freeEventNotice'
                                ? 'community.freeEventNotice'.tr
                                : 'This is a free event for all attendees',
                            style: TextStyle(color: textMuted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Attendee Limit (Optional)
                _buildFieldLabel(
                  'community.rsvpLimit'.tr.isNotEmpty &&
                          'community.rsvpLimit'.tr != 'community.rsvpLimit'
                      ? '${'community.rsvpLimit'.tr} (Optional)'
                      : 'Attendee Limit (Optional)',
                  textPrimary,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _attendeeLimitController,
                  focusNode: _attendeeLimitFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: _inputDecoration(
                    hintText: 'e.g. 50 (unlimited if empty)',
                    isDark: isDark,
                    surface: surface,
                    border: cardBorder,
                    textMuted: textMuted,
                    prefixIcon: Icon(
                      Icons.people_outline,
                      color: textMuted,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection(
    bool isDark,
    Color surface,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (_coverImage != null) ...[
              Positioned.fill(
                child: Image.file(_coverImage!, fit: BoxFit.cover),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _coverImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              InkWell(
                onTap: _pickCoverImage,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 28,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'community.uploadCover'.tr.isNotEmpty &&
                                'community.uploadCover'.tr !=
                                    'community.uploadCover'
                            ? 'community.uploadCover'.tr
                            : 'Upload Cover Photo',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'community.recommendedAspect'.tr.isNotEmpty &&
                                'community.recommendedAspect'.tr !=
                                    'community.recommendedAspect'
                            ? 'community.recommendedAspect'.tr
                            : 'Recommended 16:9 ratio',
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_isUploadingImage)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'community.uploadingImage'.tr.isNotEmpty &&
                                  'community.uploadingImage'.tr !=
                                      'community.uploadingImage'
                              ? 'community.uploadingImage'.tr
                              : 'Uploading cover image...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted) {
    return Text(
      title,
      style: TextStyle(
        color: textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color textPrimary) {
    return Text(
      label,
      style: TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSegmentedEventType(
    bool isDark,
    Color surface,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_eventType != 'Online') {
                  setState(() {
                    _eventType = 'Online';
                    _locationError = null;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: _eventType == 'Online'
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      size: 16,
                      color: _eventType == 'Online'
                          ? (isDark ? Colors.black : Colors.white)
                          : textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Online',
                        style: TextStyle(
                          color: _eventType == 'Online'
                              ? (isDark ? Colors.black : Colors.white)
                              : textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_eventType != 'In person') {
                  setState(() {
                    _eventType = 'In person';
                    _linkError = null;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: _eventType == 'In person'
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: _eventType == 'In person'
                          ? (isDark ? Colors.black : Colors.white)
                          : textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'In person',
                        style: TextStyle(
                          color: _eventType == 'In person'
                              ? (isDark ? Colors.black : Colors.white)
                              : textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required Color surface,
    required Color border,
    required Color textMuted,
    String? errorText,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: surface,
      hintText: hintText,
      hintStyle: TextStyle(color: textMuted, fontSize: 14),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? Colors.redAccent : border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null
              ? Colors.redAccent
              : (isDark ? Colors.white : Colors.black),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      counterText: '',
    );
  }

  Widget _buildScheduleChips(
    bool isDark,
    Color surface,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final chipBg = isDark ? const Color(0xFF202024) : const Color(0xFFF3F4F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  'Starts',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  key: const ValueKey('edit_start_date_chip'),
                  onTap: _pickStartDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _formatDate(_startDate),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.edit_calendar_outlined,
                          size: 14,
                          color: textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: const ValueKey('edit_start_time_chip'),
                onTap: _pickStartTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(_startTime),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  'Ends',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  key: const ValueKey('edit_end_date_chip'),
                  onTap: _pickEndDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _formatDate(_endDate ?? _startDate),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.edit_calendar_outlined,
                          size: 14,
                          color: textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: const ValueKey('edit_end_time_chip'),
                onTap: _pickEndTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(_endTime),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── GENLINK WHEEL ITEM COMPONENT ─────────────────────────────────────────────

Widget _buildGenLinkWheelItem({
  required String label,
  required bool isSelected,
  required int distance,
  required bool isDark,
  required VoidCallback onTap,
}) {
  final double opacity = isSelected
      ? 1.0
      : distance == 1
      ? 0.45
      : 0.18;
  final FontWeight weight = isSelected ? FontWeight.w700 : FontWeight.w500;
  final double fontSize = isSelected ? 18.0 : 15.0;
  final color = (isDark ? Colors.white : const Color(0xFF111111)).withValues(
    alpha: opacity,
  );

  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 100),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.2,
        ),
        child: Text(label, maxLines: 1),
      ),
    ),
  );
}

// ── GENLINK WHEEL DATE PICKER SHEET ──────────────────────────────────────────

Future<DateTime?> _showGenLinkDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  String? title,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _GenLinkDatePickerSheet(
      initialDate: initialDate ?? DateTime.now().add(const Duration(days: 1)),
      title: title,
    ),
  );
}

class _GenLinkDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final String? title;

  const _GenLinkDatePickerSheet({required this.initialDate, this.title});

  @override
  State<_GenLinkDatePickerSheet> createState() =>
      _GenLinkDatePickerSheetState();
}

class _GenLinkDatePickerSheetState extends State<_GenLinkDatePickerSheet> {
  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  late final int _minYear;
  late final int _maxYear;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _minYear = now.year;
    _maxYear = now.year + 10;

    _selectedYear = widget.initialDate.year.clamp(_minYear, _maxYear);
    _selectedMonth = widget.initialDate.month.clamp(1, 12);
    final maxDays = _daysInMonth(_selectedYear, _selectedMonth);
    _selectedDay = widget.initialDate.day.clamp(1, maxDays);

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _minYear,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  List<String> get _monthLabels {
    final trMonths = 'date.months'.tr;
    if (trMonths.isNotEmpty &&
        trMonths != 'date.months' &&
        trMonths.contains(',')) {
      final split = trMonths.split(',');
      if (split.length == 12) return split;
    }
    return const [
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
  }

  void _onMonthChanged(int index) {
    HapticFeedback.selectionClick();
    final newMonth = index + 1;
    final maxDays = _daysInMonth(_selectedYear, newMonth);
    setState(() {
      _selectedMonth = newMonth;
      if (_selectedDay > maxDays) {
        _selectedDay = maxDays;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dayController.hasClients) {
            _dayController.jumpToItem(_selectedDay - 1);
          }
        });
      }
    });
  }

  void _onYearChanged(int index) {
    HapticFeedback.selectionClick();
    final newYear = _minYear + index;
    final maxDays = _daysInMonth(newYear, _selectedMonth);
    setState(() {
      _selectedYear = newYear;
      if (_selectedDay > maxDays) {
        _selectedDay = maxDays;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_dayController.hasClients) {
            _dayController.jumpToItem(_selectedDay - 1);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161618) : Colors.white;
    final border = isDark ? const Color(0xFF2E2E32) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111111);
    final textSecondary = const Color(0xFF8E8E93);
    final handleColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.12);
    final selectedRowBg = isDark
        ? const Color(0xFF252528)
        : const Color(0xFFF2F2F7);
    final selectedRowBorder = isDark
        ? const Color(0xFF38383D)
        : const Color(0xFFE5E5EA);

    final headerTitle =
        widget.title ??
        ('community.selectDate'.tr.isNotEmpty &&
                'community.selectDate'.tr != 'community.selectDate'
            ? 'community.selectDate'.tr
            : 'Select date');
    final confirmLabel =
        'common.confirm'.tr.isNotEmpty &&
            'common.confirm'.tr != 'common.confirm'
        ? 'common.confirm'.tr
        : (Get.locale?.languageCode == 'km' ? 'បញ្ជាក់' : 'Confirm');

    final daysCount = _daysInMonth(_selectedYear, _selectedMonth);
    final monthList = _monthLabels;
    final yearCount = _maxYear - _minYear + 1;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtle drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header: Title + Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headerTitle,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Wheel Selectors Area (Day | Month | Year)
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered selected row indicator
                  Container(
                    height: 44,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selectedRowBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedRowBorder, width: 0.8),
                    ),
                  ),
                  // The 3 Wheels
                  Row(
                    children: [
                      // Day Wheel
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: _dayController,
                          itemExtent: 44.0,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.002,
                          diameterRatio: 1.6,
                          overAndUnderCenterOpacity: 1.0,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedDay = index + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= daysCount) return null;
                              final dayNum = index + 1;
                              final isSelected = dayNum == _selectedDay;
                              final distance = (dayNum - _selectedDay).abs();
                              return _buildGenLinkWheelItem(
                                label: '$dayNum',
                                isSelected: isSelected,
                                distance: distance,
                                isDark: isDark,
                                onTap: () => _dayController.animateToItem(
                                  index,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            },
                            childCount: daysCount,
                          ),
                        ),
                      ),
                      // Month Wheel
                      Expanded(
                        flex: 3,
                        child: ListWheelScrollView.useDelegate(
                          controller: _monthController,
                          itemExtent: 44.0,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.002,
                          diameterRatio: 1.6,
                          overAndUnderCenterOpacity: 1.0,
                          onSelectedItemChanged: _onMonthChanged,
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 12) return null;
                              final monthNum = index + 1;
                              final isSelected = monthNum == _selectedMonth;
                              final distance = (monthNum - _selectedMonth)
                                  .abs();
                              return _buildGenLinkWheelItem(
                                label: monthList[index],
                                isSelected: isSelected,
                                distance: distance,
                                isDark: isDark,
                                onTap: () => _monthController.animateToItem(
                                  index,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            },
                            childCount: 12,
                          ),
                        ),
                      ),
                      // Year Wheel
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: _yearController,
                          itemExtent: 44.0,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.002,
                          diameterRatio: 1.6,
                          overAndUnderCenterOpacity: 1.0,
                          onSelectedItemChanged: _onYearChanged,
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= yearCount) return null;
                              final yr = _minYear + index;
                              final isSelected = yr == _selectedYear;
                              final distance = (yr - _selectedYear).abs();
                              return _buildGenLinkWheelItem(
                                label: '$yr',
                                isSelected: isSelected,
                                distance: distance,
                                isDark: isDark,
                                onTap: () => _yearController.animateToItem(
                                  index,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            },
                            childCount: yearCount,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const ValueKey('confirm_date_button'),
                onPressed: () {
                  final result = DateTime(
                    _selectedYear,
                    _selectedMonth,
                    _selectedDay,
                  );
                  Navigator.pop(context, result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── GENLINK WHEEL TIME PICKER SHEET ──────────────────────────────────────────

Future<TimeOfDay?> _showGenLinkTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String? title,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) =>
        _GenLinkTimePickerSheet(initialTime: initialTime, title: title),
  );
}

class _GenLinkTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final String? title;

  const _GenLinkTimePickerSheet({required this.initialTime, this.title});

  @override
  State<_GenLinkTimePickerSheet> createState() =>
      _GenLinkTimePickerSheetState();
}

class _GenLinkTimePickerSheetState extends State<_GenLinkTimePickerSheet> {
  late int _selectedHour12;
  late int _selectedMinute;
  late int _selectedPeriodIndex; // 0 for AM, 1 for PM

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _periodController;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hourOfPeriod;
    _selectedHour12 = h == 0 ? 12 : h;
    _selectedMinute = widget.initialTime.minute;
    _selectedPeriodIndex = widget.initialTime.period == DayPeriod.am ? 0 : 1;

    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour12 - 1,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
    _periodController = FixedExtentScrollController(
      initialItem: _selectedPeriodIndex,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  TimeOfDay get _resultingTimeOfDay {
    int hour24;
    if (_selectedPeriodIndex == 0) {
      hour24 = _selectedHour12 == 12 ? 0 : _selectedHour12;
    } else {
      hour24 = _selectedHour12 == 12 ? 12 : _selectedHour12 + 12;
    }
    return TimeOfDay(hour: hour24, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161618) : Colors.white;
    final border = isDark ? const Color(0xFF2E2E32) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111111);
    final textSecondary = const Color(0xFF8E8E93);
    final handleColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.12);
    final selectedRowBg = isDark
        ? const Color(0xFF252528)
        : const Color(0xFFF2F2F7);
    final selectedRowBorder = isDark
        ? const Color(0xFF38383D)
        : const Color(0xFFE5E5EA);

    final headerTitle =
        widget.title ??
        ('community.selectTime'.tr.isNotEmpty &&
                'community.selectTime'.tr != 'community.selectTime'
            ? 'community.selectTime'.tr
            : 'Select time');
    final confirmLabel =
        'common.confirm'.tr.isNotEmpty &&
            'common.confirm'.tr != 'common.confirm'
        ? 'common.confirm'.tr
        : (Get.locale?.languageCode == 'km' ? 'បញ្ជាក់' : 'Confirm');

    const periods = ['AM', 'PM'];

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtle drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header: Title + Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headerTitle,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Wheel Selectors Area (Hour | Minute | AM/PM)
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered selected row indicator
                  Container(
                    height: 44,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selectedRowBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedRowBorder, width: 0.8),
                    ),
                  ),
                  // The 3 Wheels
                  Row(
                    children: [
                      // Hour Wheel (01 - 12)
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _hourController,
                          itemExtent: 44.0,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.002,
                          diameterRatio: 1.6,
                          overAndUnderCenterOpacity: 1.0,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedHour12 = index + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 12) return null;
                              final hourNum = index + 1;
                              final isSelected = hourNum == _selectedHour12;
                              final distance = (hourNum - _selectedHour12)
                                  .abs();
                              final label = hourNum.toString().padLeft(2, '0');
                              return _buildGenLinkWheelItem(
                                label: label,
                                isSelected: isSelected,
                                distance: distance,
                                isDark: isDark,
                                onTap: () => _hourController.animateToItem(
                                  index,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            },
                            childCount: 12,
                          ),
                        ),
                      ),
                      // Minute Wheel (00 - 59)
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _minuteController,
                          itemExtent: 44.0,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.002,
                          diameterRatio: 1.6,
                          overAndUnderCenterOpacity: 1.0,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMinute = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 60) return null;
                              final isSelected = index == _selectedMinute;
                              final distance = (index - _selectedMinute).abs();
                              final label = index.toString().padLeft(2, '0');
                              return _buildGenLinkWheelItem(
                                label: label,
                                isSelected: isSelected,
                                distance: distance,
                                isDark: isDark,
                                onTap: () => _minuteController.animateToItem(
                                  index,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            },
                            childCount: 60,
                          ),
                        ),
                      ),
                      // AM / PM Wheel
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _periodController,
                          itemExtent: 44.0,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.002,
                          diameterRatio: 1.6,
                          overAndUnderCenterOpacity: 1.0,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedPeriodIndex = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= 2) return null;
                              final isSelected = index == _selectedPeriodIndex;
                              final distance = (index - _selectedPeriodIndex)
                                  .abs();
                              return _buildGenLinkWheelItem(
                                label: periods[index],
                                isSelected: isSelected,
                                distance: distance,
                                isDark: isDark,
                                onTap: () => _periodController.animateToItem(
                                  index,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            },
                            childCount: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const ValueKey('confirm_time_button'),
                onPressed: () => Navigator.pop(context, _resultingTimeOfDay),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
