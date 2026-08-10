import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_details_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

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

  static const List<String> _categoryKeys = [
    'community.workshop',
    'community.seminar',
    'community.hackathon',
    'community.categoryOther',
  ];

  bool get _canCreate =>
      _titleController.text.trim().isNotEmpty && 
      _selectedDate != null &&
      (_eventType == 'Online' ? _linkController.text.trim().isNotEmpty : _locationController.text.trim().isNotEmpty);

  String get _formattedDate {
    if (_selectedDate == null) return '';
    final d = _selectedDate!;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month - 1];
    final dateStr = '$dayName, $monthName ${d.day}';
    
    if (_selectedTime != null) {
      final h = _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
      final m = _selectedTime!.minute.toString().padLeft(2, '0');
      final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      return '$dateStr, $h:$m $period';
    }
    return dateStr;
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
    _linkController.addListener(() => setState(() {}));
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
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _linkController.text.trim().isNotEmpty ||
        _selectedDate != null ||
        _selectedCategory != null ||
        _coverImage != null;

    if (hasContent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2228),
          title: Text(
            'community.discardDraft'.tr,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'community.discardMessage'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'community.keepEditing'.tr,
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'community.discard'.tr,
                style: const TextStyle(color: Colors.redAccent),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (pickedTime != null) {
        setState(() => _selectedTime = pickedTime);
      }
    }
  }

  void _submit() async {
    if (!_canCreate || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Short UI feedback delay (local-first, no network)
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Build an EventModel from the form data
    final newEvent = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      subtitle: _descController.text.trim().isNotEmpty
          ? _descController.text.trim().split('\n').first
          : '',
      organizerName: 'Me',
      eventType: _eventType,
      location: _eventType == 'In person' ? _locationController.text.trim() : '',
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
    final controller = Get.find<CommunityController>();
    controller.createEvent(newEvent);

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    AppNotificationBanner.showSuccess(
      context: context,
      title: 'community.eventCreated'.tr,
      message: 'community.eventCreatedMsg'.tr,
    );

    // Navigate to the freshly-created event's detail screen
    Get.off(() => EventDetailsScreen(event: newEvent));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Strict Dark Theme based on instructions
    final bg = isDark ? Colors.black : Colors.white;
    final inputBg = isDark ? const Color(0xFF181818) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF666666);
    final cardBorder = isDark ? const Color(0xFF303030) : const Color(0xFFDDDDDD);
    final imagePlaceholderBg = isDark ? const Color(0xFF181818) : const Color(0xFFF0F2F5);

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
            'Create Event',
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
                onPressed: _canCreate && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0),
                  disabledForegroundColor: isDark ? Colors.white30 : Colors.black38,
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
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner Image Area ─────────────────────────────────────────
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * (9 / 16),
                decoration: BoxDecoration(
                  color: imagePlaceholderBg,
                  border: Border(
                    bottom: BorderSide(color: cardBorder),
                  ),
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
                              Icon(Icons.add_photo_alternate_outlined, color: textMuted, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Upload cover image',
                                style: TextStyle(color: textMuted, fontSize: 14),
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
                                  color: isDark ? Colors.black54 : Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: textPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Event Type ──────────────────────────────────────────
                    _buildLabel('Event type', textMuted),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRadioButton('Online', textPrimary),
                        const SizedBox(width: 24),
                        _buildRadioButton('In person', textPrimary),
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
                      decoration: _inputDeco(cardBorder: cardBorder, textPrimary: textPrimary, inputBg: inputBg),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _eventType == 'Online' ? _linkFocus.requestFocus() : _locationFocus.requestFocus(),
                    ),
                    const SizedBox(height: 24),

                    // ── Date and Time ───────────────────────────────────────
                    _buildLabel('Date & time*', textMuted),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      child: IgnorePointer(
                        child: TextField(
                          controller: TextEditingController(text: _formattedDate),
                          style: TextStyle(color: textPrimary, fontSize: 16),
                          decoration: _inputDeco(cardBorder: cardBorder, textPrimary: textPrimary, inputBg: inputBg).copyWith(
                            hintText: 'Select date and time',
                            hintStyle: TextStyle(color: textMuted, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your event timezone is set to Local Time',
                      style: TextStyle(color: textMuted, fontSize: 13),
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
                        decoration: _inputDeco(cardBorder: cardBorder, textPrimary: textPrimary, inputBg: inputBg).copyWith(
                          hintText: 'e.g. https://meet.google.com/...',
                          hintStyle: TextStyle(color: textMuted, fontSize: 16),
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
                        decoration: _inputDeco(cardBorder: cardBorder, textPrimary: textPrimary, inputBg: inputBg).copyWith(
                          hintText: 'Add event location',
                          hintStyle: TextStyle(color: textMuted, fontSize: 16),
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
                      style: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
                      decoration: _inputDeco(cardBorder: cardBorder, textPrimary: textPrimary, inputBg: inputBg).copyWith(
                        hintText: 'Tell people about your event',
                        hintStyle: TextStyle(color: textMuted, fontSize: 16),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    
                    const SizedBox(height: 24),

                    // ── Category (Preserved GenLink Feature) ────────────────
                    _buildLabel('Category (Optional)', textMuted),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? textPrimary : inputBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : cardBorder,
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
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildRadioButton(String title, Color textPrimary) {
    final isSelected = _eventType == title;
    return GestureDetector(
      onTap: () => setState(() => _eventType = title),
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
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    required Color cardBorder,
    required Color textPrimary,
    required Color inputBg,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: textPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      counterStyle: TextStyle(fontSize: 13), // for maxLength counter
    );
  }
}
