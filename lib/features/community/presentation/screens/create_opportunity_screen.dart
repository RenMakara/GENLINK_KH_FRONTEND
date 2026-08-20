import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import 'widgets/author_row.dart';

/// Create Opportunity Screen — Career tab creation flow.
///
/// Fields: Title, Company, Type (Full-Time/Part-Time/Internship), Description.
/// Mirrors the existing Career data structure (JobCard fields).
/// Black/white design — zero cyan/blue.
class CreateOpportunityScreen extends StatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  State<CreateOpportunityScreen> createState() => _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _companyFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  bool _isSubmitting = false;
  String? _selectedType;

  static const List<String> _typeKeys = [
    'community.opportunityFullTime',
    'community.opportunityPartTime',
    'community.opportunityInternship',
  ];

  bool get _canPost =>
      _titleController.text.trim().isNotEmpty &&
      _companyController.text.trim().isNotEmpty &&
      _selectedType != null;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _companyController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descController.dispose();
    _titleFocus.dispose();
    _companyFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _onBackPress() {
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _companyController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _selectedType != null;

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

  void _submit() async {
    if (!_canPost || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Simulate network delay (replace with actual repo call when backend is ready)
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    AppNotificationBanner.showSuccess(
      context: context,
      title: 'community.opportunityPosted'.tr,
      message: 'community.opportunityPostedMsg'.tr,
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
            'community.createOpportunity'.tr,
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
                onPressed: _canPost && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPost
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
              // ── Author identity row ────────────────────────────────────
              AuthorRow(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted),
              const SizedBox(height: 20),

              // ── Title ──────────────────────────────────────────────
              _buildLabel('Title', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                maxLines: 1,
                maxLength: 120,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
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

              // ── Company ────────────────────────────────────────────────
              _buildLabel('Company', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _companyController,
                focusNode: _companyFocus,
                maxLines: 1,
                maxLength: 100,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: _inputDecoration(
                  hint: 'community.opportunityCompany'.tr,
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

              // ── Type Selector ──────────────────────────────────────────
              _buildLabel('community.opportunityType'.tr, textMuted),
              const SizedBox(height: 8),
              Row(
                children: _typeKeys.map((key) {
                  final isSelected = _selectedType == key;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: key != _typeKeys.last ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black87)
                                : inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : cardBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              key.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Description ────────────────────────────────────────────
              _buildLabel('Description', textMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                focusNode: _descFocus,
                minLines: 5,
                maxLines: null,
                maxLength: 2000,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
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
      hintStyle: TextStyle(color: textMuted, fontSize: 15, fontWeight: FontWeight.w400),
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
