import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_error.dart';
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
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _attendeeLimitController = TextEditingController();

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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _linkController.text.trim().isNotEmpty ||
        _priceController.text.trim().isNotEmpty ||
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
            'community.discardDraft'.tr.isNotEmpty &&
                    'community.discardDraft'.tr != 'community.discardDraft'
                ? 'community.discardDraft'.tr
                : 'Discard Event?',
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'community.discardMessage'.tr.isNotEmpty &&
                    'community.discardMessage'.tr != 'community.discardMessage'
                ? 'community.discardMessage'.tr
                : 'You have unsaved changes. Are you sure you want to discard this event?',
            style: TextStyle(color: contentColor, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'community.keepEditing'.tr.isNotEmpty &&
                        'community.keepEditing'.tr != 'community.keepEditing'
                    ? 'community.keepEditing'.tr
                    : 'Keep Editing',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'community.discard'.tr.isNotEmpty &&
                        'community.discard'.tr != 'community.discard'
                    ? 'community.discard'.tr
                    : 'Discard',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialDate = _startDate ?? DateTime.now().add(const Duration(days: 1));

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
        _startDate = picked;
        _endDate = picked;
        _dateError = null;
      });

      if (!mounted) return;

      final initialTime = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
      final pickedTime = await _showCustomTimePicker(
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
        });
      }
    }
  }

  void _showCategoryBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161618) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final border = isDark ? const Color(0xFF2E2E32) : const Color(0xFFE5E7EB);
    final tileActive = isDark ? const Color(0xFF222226) : const Color(0xFFF3F4F6);

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        color: isSelected ? tileActive : Colors.transparent,
                        child: Row(
                          children: [
                            Text(
                              _getCategoryIcon(cat),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _getCategoryLabel(cat),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  String _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'technology':
        return '💻';
      case 'design':
        return '🎨';
      case 'business':
        return '💼';
      case 'career':
        return '🚀';
      case 'education':
        return '📚';
      case 'social':
        return '🎉';
      case 'entertainment':
        return '🎬';
      default:
        return '📌';
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
    final endDateTime = _calculatedEndDateTime ??
        startDateTime.add(const Duration(hours: 2));

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
        setState(() => _linkError = 'Meeting URL must start with http:// or https://');
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
        status: 'PUBLISHED',
      );

      final controller = Get.isRegistered<CommunityController>()
          ? Get.find<CommunityController>()
          : Get.put(CommunityController());

      final createdEvent = await controller.createEvent(
        request,
        coverImageFile: _coverImage,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppNotificationBanner.showSuccess(
        context: context,
        title: 'community.eventCreated'.tr.isNotEmpty &&
                'community.eventCreated'.tr != 'community.eventCreated'
            ? 'community.eventCreated'.tr
            : 'Event Created',
        message: 'community.eventCreatedMsg'.tr.isNotEmpty &&
                'community.eventCreatedMsg'.tr != 'community.eventCreatedMsg'
            ? 'community.eventCreatedMsg'.tr
            : 'Your event has been published successfully.',
      );

      if (widget.returnCreatedEvent) {
        Get.back(result: createdEvent);
      } else {
        Get.off(() => EventDetailsScreen(event: createdEvent));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final errorMsg = e is AppError
          ? e.message
          : 'Failed to create event. Please check your connection and try again.';

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
    final cardBorder = isDark ? const Color(0xFF26262B) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textMuted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
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
                  disabledBackgroundColor:
                      isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE5E7EB),
                  disabledForegroundColor:
                      isDark ? Colors.white30 : Colors.black38,
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
                    : const Text(
                        'Create',
                        style: TextStyle(
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
                _buildSectionHeader('community.coverImage'.tr.isNotEmpty &&
                        'community.coverImage'.tr != 'community.coverImage'
                    ? 'community.coverImage'.tr
                    : 'EVENT COVER PHOTO', textMuted),
                const SizedBox(height: 8),
                _buildCoverImageSection(isDark, surface, cardBorder, textPrimary, textMuted),

                const SizedBox(height: 24),

                // ── 2. GENERAL INFO ──────────────────────────────────────────
                _buildSectionHeader('community.eventDetails'.tr.isNotEmpty &&
                        'community.eventDetails'.tr != 'community.eventDetails'
                    ? 'community.eventDetails'.tr
                    : 'EVENT DETAILS', textMuted),
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
                    prefixIcon: Icon(Icons.title_rounded, color: textMuted, size: 20),
                  ),
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Description
                _buildFieldLabel('community.eventDescription'.tr.isNotEmpty &&
                        'community.eventDescription'.tr != 'community.eventDescription'
                    ? 'community.eventDescription'.tr
                    : 'Description', textPrimary),
                const SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  focusNode: _descFocus,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 5000,
                  style: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
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
                _buildFieldLabel('community.category'.tr.isNotEmpty &&
                        'community.category'.tr != 'community.category'
                    ? 'community.category'.tr
                    : 'Category', textPrimary),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showCategoryBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _selectedCategory != null
                                  ? Icons.category
                                  : Icons.category_outlined,
                              color: _selectedCategory != null
                                  ? (isDark ? Colors.white : Colors.black)
                                  : textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _selectedCategory != null
                                  ? _getCategoryLabel(_selectedCategory!)
                                  : ('community.selectCategory'.tr.isNotEmpty &&
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
                            ),
                          ],
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
                        hintText: 'Select date and time',
                        errorText: _dateError,
                        isDark: isDark,
                        surface: surface,
                        border: cardBorder,
                        textMuted: textMuted,
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: textMuted, size: 18),
                      ),
                    ),
                  ),
                ),

                if (_timeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _timeError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 24),

                // ── 4. EVENT TYPE ───────────────────────────────────────
                _buildSectionHeader('community.eventType'.tr.isNotEmpty &&
                        'community.eventType'.tr != 'community.eventType'
                    ? 'community.eventType'.tr
                    : 'EVENT TYPE', textMuted),
                const SizedBox(height: 12),

                _buildSegmentedEventType(isDark, surface, cardBorder, textPrimary, textMuted),

                const SizedBox(height: 16),

                // Location / Meeting URL depending on Event Type
                if (_eventType == 'In person') ...[
                  Row(
                    children: [
                      _buildFieldLabel('Location*', textPrimary),
                    ],
                  ),
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
                      prefixIcon: Icon(Icons.location_on_outlined, color: textMuted, size: 20),
                    ),
                    textInputAction: TextInputAction.next,
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
                      prefixIcon: Icon(Icons.link_rounded, color: textMuted, size: 20),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ],

                const SizedBox(height: 24),

                // ── 5. TICKETING & CAPACITY ──────────────────────────────
                _buildSectionHeader('community.ticketing'.tr.isNotEmpty &&
                        'community.ticketing'.tr != 'community.ticketing'
                    ? 'community.ticketing'.tr
                    : 'TICKETING & CAPACITY', textMuted),
                const SizedBox(height: 12),

                // Paid toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              _isPaid ? Icons.monetization_on : Icons.money_off_outlined,
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
                                            'community.paidEvent'.tr != 'community.paidEvent'
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
                                            'community.paidEventDesc'.tr != 'community.paidEventDesc'
                                        ? 'community.paidEventDesc'.tr
                                        : 'Require ticket purchase to attend',
                                    style: TextStyle(color: textMuted, fontSize: 12),
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
                        activeTrackColor: isDark ? Colors.white38 : Colors.black26,
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
                            _buildFieldLabel('community.price'.tr.isNotEmpty &&
                                    'community.price'.tr != 'community.price'
                                ? '${'community.price'.tr}*'
                                : 'Price*', textPrimary),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _priceController,
                              focusNode: _priceFocus,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              style: TextStyle(color: textPrimary, fontSize: 15),
                              decoration: _inputDecoration(
                                hintText: '0.00',
                                errorText: _priceError,
                                isDark: isDark,
                                surface: surface,
                                border: cardBorder,
                                textMuted: textMuted,
                                prefixIcon: Icon(Icons.attach_money, color: textMuted, size: 20),
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
                            _buildFieldLabel('community.currency'.tr.isNotEmpty &&
                                    'community.currency'.tr != 'community.currency'
                                ? 'community.currency'.tr
                                : 'Currency', textPrimary),
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
                                      onTap: () => setState(() => _selectedCurrency = 'USD'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: _selectedCurrency == 'USD'
                                              ? (isDark ? Colors.white : Colors.black)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'USD',
                                          style: TextStyle(
                                            color: _selectedCurrency == 'USD'
                                                ? (isDark ? Colors.black : Colors.white)
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
                                      onTap: () => setState(() => _selectedCurrency = 'KHR'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: _selectedCurrency == 'KHR'
                                              ? (isDark ? Colors.white : Colors.black)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'KHR',
                                          style: TextStyle(
                                            color: _selectedCurrency == 'KHR'
                                                ? (isDark ? Colors.black : Colors.white)
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: textMuted, size: 18),
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
                _buildFieldLabel('community.rsvpLimit'.tr.isNotEmpty &&
                        'community.rsvpLimit'.tr != 'community.rsvpLimit'
                    ? '${'community.rsvpLimit'.tr} (Optional)'
                    : 'Attendee Limit (Optional)', textPrimary),
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
                    prefixIcon: Icon(Icons.people_outline, color: textMuted, size: 20),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
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
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
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
                                'community.uploadCover'.tr != 'community.uploadCover'
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
                                'community.recommendedAspect'.tr != 'community.recommendedAspect'
                            ? 'community.recommendedAspect'.tr
                            : 'Recommended 16:9 ratio',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
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
                        const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        const SizedBox(height: 10),
                        Text(
                          'community.uploadingImage'.tr.isNotEmpty &&
                                  'community.uploadingImage'.tr != 'community.uploadingImage'
                              ? 'community.uploadingImage'.tr
                              : 'Uploading cover image...',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
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
                    Text(
                      'Online',
                      style: TextStyle(
                        color: _eventType == 'Online'
                            ? (isDark ? Colors.black : Colors.white)
                            : textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                    Text(
                      'In person',
                      style: TextStyle(
                        color: _eventType == 'In person'
                            ? (isDark ? Colors.black : Colors.white)
                            : textMuted,
                        fontWeight: FontWeight.bold,
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
          color: errorText != null ? Colors.redAccent : (isDark ? Colors.white : Colors.black),
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
}

// ── TIME PICKER SHEET (GenLink Themed) ───────────────────────────────────────

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

class _GenLinkTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;

  const _GenLinkTimePickerSheet({required this.initialTime});

  @override
  State<_GenLinkTimePickerSheet> createState() => _GenLinkTimePickerSheetState();
}

class _GenLinkTimePickerSheetState extends State<_GenLinkTimePickerSheet> {
  late int _selectedHour12;
  late int _selectedMinute;
  late DayPeriod _selectedPeriod;

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
            Text(
              selectTimeTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: surfaceUnselected,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = DayPeriod.am),
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
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = DayPeriod.pm),
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
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                    0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55,
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
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                      onPressed: () => Navigator.pop(context, _resultingTimeOfDay),
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
