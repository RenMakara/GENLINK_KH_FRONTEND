import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../controllers/community_controller.dart';
import 'widgets/author_row.dart';

class CreateOpportunityScreen extends StatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  State<CreateOpportunityScreen> createState() =>
      _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _applyLinkController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _companyFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _applyLinkFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  bool _isSubmitting = false;
  String _selectedType = 'INTERNSHIP';
  DateTime? _selectedDeadline;

  static const List<Map<String, String>> _types = [
    {'key': 'INTERNSHIP', 'label': 'Internship'},
    {'key': 'SCHOLARSHIP', 'label': 'Scholarship'},
    {'key': 'JOB', 'label': 'Job'},
    {'key': 'HACKATHON', 'label': 'Hackathon'},
    {'key': 'VOLUNTEER', 'label': 'Volunteer'},
  ];

  bool get _canPost =>
      _titleController.text.trim().isNotEmpty &&
      _companyController.text.trim().isNotEmpty &&
      _selectedType.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _companyController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
    _applyLinkController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _applyLinkController.dispose();
    _descController.dispose();
    _titleFocus.dispose();
    _companyFocus.dispose();
    _locationFocus.dispose();
    _applyLinkFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _onBackPress() async {
    final hasContent =
        _titleController.text.trim().isNotEmpty ||
        _companyController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _applyLinkController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _selectedDeadline != null;

    if (hasContent) {
      final confirmed = await GenLinkConfirmDialog.showDiscard(
        context: context,
        title: 'community.discardDraft'.tr,
        message: 'community.discardMessage'.tr,
        confirmLabel: 'community.discard'.tr,
        cancelLabel: 'community.keepEditing'.tr,
      );
      if (confirmed && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDeadline = picked);
    }
  }

  void _submit() async {
    if (!_canPost || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final commController = Get.find<CommunityController>();
      final created = await commController.repository.createOpportunity(
        title: _titleController.text.trim(),
        organization: _companyController.text.trim(),
        type: _selectedType,
        description: _descController.text.trim(),
        deadline: _selectedDeadline,
        location: _locationController.text.trim(),
        applyLink: _applyLinkController.text.trim(),
      );

      commController.opportunities.insert(0, created);
      commController.opportunities.refresh();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppNotificationBanner.showSuccess(
        context: context,
        title: 'community.opportunityPosted'.tr,
        message: 'community.opportunityPostedMsg'.tr,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final msg = e is AppError
          ? e.message
          : 'Posting opportunities requires Administrator role.';
      AppNotificationBanner.showWarning(
        context: context,
        title: 'Admin Only',
        message: msg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark
        ? const Color(0xFF8E9297)
        : const Color(0xFF9E9E9E);
    final cardBorder = isDark
        ? const Color(0xFF2B313A)
        : const Color(0xFFE2E4E8);
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
            'community.createOpportunity'.tr,
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
                top: 10,
                bottom: 10,
                left: 4,
              ),
              child: ElevatedButton(
                onPressed: _canPost && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPost
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFE0E0E0)),
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF222222)
                      : const Color(0xFFE0E0E0),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
                        'community.post'.tr,
                        style: TextStyle(
                          color: _canPost
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white30 : Colors.black38),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
              AuthorRow(
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 20),

              _buildLabel('Title *', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                maxLines: 1,
                maxLength: 120,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  hint: 'community.opportunityTitle'.tr,
                  isDark: isDark,
                  textMuted: textMuted,
                  inputBg: inputBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _companyFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              _buildLabel('Organization / Company *', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _companyController,
                focusNode: _companyFocus,
                maxLines: 1,
                maxLength: 100,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  hint: 'community.opportunityCompany'.tr,
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

              _buildLabel('Location', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                focusNode: _locationFocus,
                maxLines: 1,
                maxLength: 120,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  hint: 'e.g. Phnom Penh / Remote',
                  isDark: isDark,
                  textMuted: textMuted,
                  inputBg: inputBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _applyLinkFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              _buildLabel('Application URL / Link', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _applyLinkController,
                focusNode: _applyLinkFocus,
                maxLines: 1,
                keyboardType: TextInputType.url,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  hint: 'https://example.com/apply',
                  isDark: isDark,
                  textMuted: textMuted,
                  inputBg: inputBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _descFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              _buildLabel('community.opportunityType'.tr, textMuted),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((typeMap) {
                    final key = typeMap['key']!;
                    final label = typeMap['label']!;
                    final isSelected = _selectedType == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black87)
                                : inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : cardBorder,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              _buildLabel('Application Deadline', textMuted),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: _selectedDeadline != null
                            ? textPrimary
                            : textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDeadline != null
                            ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}'
                            : 'Select deadline date (optional)',
                        style: TextStyle(
                          color: _selectedDeadline != null
                              ? textPrimary
                              : textMuted,
                          fontSize: 14.5,
                          fontWeight: _selectedDeadline != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedDeadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedDeadline = null),
                          child: Icon(Icons.clear, size: 18, color: textMuted),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildLabel('Description', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                focusNode: _descFocus,
                minLines: 5,
                maxLines: null,
                maxLength: 2000,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: TextStyle(color: textPrimary, fontSize: 15, height: 1.5),
                decoration: _inputDecoration(
                  hint: 'community.opportunityDesc'.tr,
                  isDark: isDark,
                  textMuted: textMuted,
                  inputBg: inputBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
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
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    required Color textMuted,
    required Color inputBg,
    required Color cardBorder,
    required Color textPrimary,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: textMuted,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
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
