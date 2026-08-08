import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import 'widgets/author_row.dart';

/// Create Event Screen — Event tab creation flow.
///
/// Fields: Title, Description, Category, Date & Time, Location.
/// Black/white design — zero cyan/blue.
/// Reuses the same event data shape as EventDetailsScreen.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  bool _isSubmitting = false;
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
      _titleController.text.trim().isNotEmpty && _selectedDate != null;

  String get _formattedDate {
    if (_selectedDate == null) return '';
    final d = _selectedDate!;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
    if (_selectedTime != null) {
      final h = _selectedTime!.hour.toString().padLeft(2, '0');
      final m = _selectedTime!.minute.toString().padLeft(2, '0');
      return '$dateStr, $h:$m';
    }
    return dateStr;
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _onBackPress() {
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _selectedDate != null ||
        _selectedCategory != null;

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      // Optionally pick time
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

    // Simulate network delay (replace with actual repo call when backend is ready)
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    AppNotificationBanner.showSuccess(
      context: context,
      title: 'community.eventCreated'.tr,
      message: 'community.eventCreatedMsg'.tr,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? const Color(0xFF8E9297) : const Color(0xFF9E9E9E);
    final cardBorder = isDark ? const Color(0xFF2B313A) : const Color(0xFFE2E4E8);
    final inputBg = isDark ? const Color(0xFF1A1D22) : const Color(0xFFF7F8FA);

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
            'community.createEvent'.tr,
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10, left: 4),
              child: ElevatedButton(
                onPressed: _canCreate && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canCreate
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0)),
                  disabledBackgroundColor: isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        'community.createEvent'.tr,
                        style: TextStyle(
                          color: _canCreate
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white30 : Colors.black38),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: cardBorder),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Author identity row ────────────────────────────────────
              AuthorRow(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted),
              const SizedBox(height: 20),

              // ── Event Title ────────────────────────────────────────────
              _buildLabel('TITLE *', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                maxLines: 2,
                minLines: 1,
                maxLength: 100,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                decoration: _inputDeco(
                  hint: 'community.eventTitle'.tr,
                  isDark: isDark,
                  textMuted: textMuted,
                  inputBg: inputBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  fontSize: 18,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _descFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              // ── Description ────────────────────────────────────────────
              _buildLabel('DESCRIPTION', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                focusNode: _descFocus,
                minLines: 4,
                maxLines: null,
                maxLength: 2000,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                style: TextStyle(color: textPrimary, fontSize: 15, height: 1.5),
                decoration: _inputDeco(
                  hint: 'community.eventDesc'.tr,
                  isDark: isDark,
                  textMuted: textMuted,
                  inputBg: inputBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _locationFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              // ── Category ───────────────────────────────────────────────
              _buildLabel('community.eventCategory'.tr.toUpperCase(), textMuted),
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
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black87)
                            : inputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : cardBorder,
                        ),
                      ),
                      child: Text(
                        key.tr,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Date & Time ────────────────────────────────────────────
              _buildLabel('community.eventDate'.tr.toUpperCase(), textMuted),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedDate != null ? textPrimary.withValues(alpha: 0.4) : cardBorder,
                      width: _selectedDate != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: _selectedDate != null ? textPrimary : textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? _formattedDate
                              : 'community.selectDate'.tr,
                          style: TextStyle(
                            color: _selectedDate != null ? textPrimary : textMuted,
                            fontSize: 15,
                            fontWeight: _selectedDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedDate = null;
                            _selectedTime = null;
                          }),
                          child: Icon(Icons.close, color: textMuted, size: 18),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Location ───────────────────────────────────────────────
              _buildLabel('community.eventLocation'.tr.toUpperCase(), textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                focusNode: _locationFocus,
                maxLines: 1,
                maxLength: 150,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: _inputDeco(
                  hint: 'e.g. ACLEDA Institute, Phnom Penh',
                  isDark: isDark,
                  textMuted: textMuted,
                  inputBg: inputBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  prefixIcon: Icon(Icons.location_on_outlined, color: textMuted, size: 20),
                ),
              ),

              const SizedBox(height: 32),
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
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required bool isDark,
    required Color textMuted,
    required Color inputBg,
    required Color cardBorder,
    required Color textPrimary,
    double fontSize = 15,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textMuted, fontSize: fontSize, fontWeight: FontWeight.w400),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
