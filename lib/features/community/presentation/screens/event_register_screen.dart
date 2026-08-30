import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_success_screen.dart';

class EventRegisterScreen extends StatefulWidget {
  final EventModel event;

  const EventRegisterScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventRegisterScreen> createState() => _EventRegisterScreenState();
}

class _EventRegisterScreenState extends State<EventRegisterScreen> {
  // Form controllers - all personal fields start EMPTY per requirements
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _scrollController = ScrollController();

  String? _selectedUniversity;
  String? _selectedFaculty;
  String? _selectedYear;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  // Validation error strings
  String? _fullNameError;
  String? _universityError;
  String? _facultyError;
  String? _yearError;
  String? _emailError;
  String? _phoneError;
  String? _termsError;

  // Focus nodes for keyboard and scrolling UX
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final List<String> _universities = const [
    'ACLEDA University of Business (AUB)',
    'Royal University of Phnom Penh (RUPP)',
    'Institute of Technology of Cambodia (ITC)',
    'Cambodia Academy of Digital Technology (CADT)',
    'American University of Phnom Penh (AUPP)',
    'National University of Management (NUM)',
    'University of Cambodia (UC)',
    'Paragon International University',
    'Paññāsāstra University of Cambodia (PUC)',
    'Royal University of Law and Economics (RULE)',
    'Kirirom Institute of Technology (KIT)',
    'National Institute of Business (NIB)',
    'Other / Not Listed',
  ];

  final List<String> _faculties = const [
    'Computer Science & IT',
    'Software Development & Engineering',
    'Data Science & Artificial Intelligence',
    'Cybersecurity & Networking',
    'Business Administration & Management',
    'Banking, Finance & Fintech',
    'Accounting & Auditing',
    'Digital Marketing & Media',
    'Graphic Design & Multimedia',
    'Civil & Mechanical Engineering',
    'Law & International Relations',
    'Foreign Languages & Humanities',
    'Economics & Trade',
    'Other / General Studies',
  ];

  final List<String> _studyYears = const [
    'Year 1 (Freshman)',
    'Year 2 (Sophomore)',
    'Year 3 (Junior)',
    'Year 4 (Senior)',
    'Year 5 (Engineering / Extended)',
    'Postgraduate / Master\'s',
    'Fresh Graduate / Alumni',
    'Other',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      final name = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      _fullNameError = name.isEmpty ? 'community.fullNameRequired'.tr : null;
      _universityError = _selectedUniversity == null ? 'community.universityRequired'.tr : null;
      _facultyError = _selectedFaculty == null ? 'community.facultyRequired'.tr : null;
      _yearError = _selectedYear == null ? 'community.yearRequired'.tr : null;

      if (email.isEmpty) {
        _emailError = 'community.emailRequired'.tr;
      } else if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,6}$').hasMatch(email)) {
        _emailError = 'community.invalidEmail'.tr;
      } else {
        _emailError = null;
      }

      if (phone.isEmpty) {
        _phoneError = 'community.phoneRequired'.tr;
      } else if (phone.replaceAll(RegExp(r'[^\d]'), '').length < 8) {
        _phoneError = 'community.invalidPhone'.tr;
      } else {
        _phoneError = null;
      }

      _termsError = !_agreedToTerms ? 'community.termsRequired'.tr : null;
    });

    return _fullNameError == null &&
        _universityError == null &&
        _facultyError == null &&
        _yearError == null &&
        _emailError == null &&
        _phoneError == null &&
        _termsError == null;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    // Remove active keyboard
    FocusScope.of(context).unfocus();

    if (!_validateForm()) {
      HapticFeedback.lightImpact();
      // Scroll smoothly to top if needed
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    // Small delay to simulate network registration call
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    // Mark RSVP in model and controller so state persists reactively
    widget.event.isRsvped = true;
    widget.event.attendeesCount += 1;

    final ctrl = Get.isRegistered<CommunityController>() ? Get.find<CommunityController>() : null;
    if (ctrl != null) {
      final ev = ctrl.events.firstWhereOrNull((e) => e.id == widget.event.id);
      if (ev != null && !ev.isRsvped) {
        ev.isRsvped = true;
        ev.attendeesCount += 1;
        ctrl.events.refresh();
      }
    }

    setState(() => _isSubmitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EventSuccessScreen(event: widget.event),
      ),
    );
  }

  void _openUniversitySelector() {
    _showSearchableSelectorSheet(
      title: 'community.selectUniversity'.tr,
      searchHint: 'community.searchUniversity'.tr,
      items: _universities,
      selectedItem: _selectedUniversity,
      onSelected: (val) {
        setState(() {
          _selectedUniversity = val;
          _universityError = null;
        });
      },
    );
  }

  void _openFacultySelector() {
    _showSearchableSelectorSheet(
      title: 'community.selectFaculty'.tr,
      searchHint: 'community.searchFaculty'.tr,
      items: _faculties,
      selectedItem: _selectedFaculty,
      onSelected: (val) {
        setState(() {
          _selectedFaculty = val;
          _facultyError = null;
        });
      },
    );
  }

  void _openYearSelector() {
    _showSearchableSelectorSheet(
      title: 'community.selectYearOfStudy'.tr,
      searchHint: 'community.searchFaculty'.tr,
      items: _studyYears,
      selectedItem: _selectedYear,
      isSearchable: false,
      onSelected: (val) {
        setState(() {
          _selectedYear = val;
          _yearError = null;
        });
      },
    );
  }

  void _showSearchableSelectorSheet({
    required String title,
    required String searchHint,
    required List<String> items,
    required String? selectedItem,
    required ValueChanged<String> onSelected,
    bool isSearchable = true,
  }) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;
    final searchBg = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.lightBgSecondary;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.isEmpty
                ? items
                : items.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textSecondary, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar (if enabled)
                  if (isSearchable && items.length > 5) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: TextField(
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          onChanged: (val) => setSheetState(() => query = val),
                          decoration: InputDecoration(
                            hintText: searchHint,
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : AppColors.lightTextMuted,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark ? Colors.white38 : AppColors.lightTextMuted,
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // List
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: borderSubtle),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = item == selectedItem;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          title: Text(
                            item,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? AppColors.communityAccent : const Color(0xFF6D28D9))
                                  : textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: isDark ? AppColors.communityAccent : const Color(0xFF6D28D9),
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTermsModal(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'community.eventTermsTitle'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'community.eventTermsContent'.tr,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'community.understand'.tr,
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted = isDark ? Colors.white54 : AppColors.lightTextMuted;
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    // Check if already registered
    final isAlreadyRegistered = widget.event.isRsvped;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'community.registerForEvent'.tr,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Compact Event Summary Card ────────────────────────
                    _buildEventSummaryCard(
                      context: context,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderSubtle: borderSubtle,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 20),

                    // If already registered, show informative banner
                    if (isAlreadyRegistered) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'community.alreadyRegistered'.tr,
                                    style: const TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'community.alreadyRegisteredMsg'.tr,
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── SECTION 1: Your Information ───────────────────────
                    _buildSectionHeader('community.yourInformation'.tr, isDark),
                    const SizedBox(height: 10),

                    _buildModernTextField(
                      label: 'community.fullNameReq'.tr,
                      hint: 'community.enterFullName'.tr,
                      controller: _fullNameController,
                      focusNode: _fullNameFocus,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      errorText: _fullNameError,
                      isDark: isDark,
                      onChanged: (_) {
                        if (_fullNameError != null) {
                          setState(() => _fullNameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildModernSelectorTile(
                      label: 'community.universityReq'.tr,
                      placeholder: 'community.selectUniversity'.tr,
                      value: _selectedUniversity,
                      errorText: _universityError,
                      isDark: isDark,
                      onTap: _openUniversitySelector,
                    ),

                    const SizedBox(height: 22),

                    // ── SECTION 2: Academic Information ──────────────────
                    _buildSectionHeader('community.academicInformation'.tr, isDark),
                    const SizedBox(height: 10),

                    _buildModernSelectorTile(
                      label: 'community.facultyReq'.tr,
                      placeholder: 'community.selectFaculty'.tr,
                      value: _selectedFaculty,
                      errorText: _facultyError,
                      isDark: isDark,
                      onTap: _openFacultySelector,
                    ),
                    const SizedBox(height: 14),

                    _buildModernSelectorTile(
                      label: 'community.yearOfStudyReq'.tr,
                      placeholder: 'community.selectYearOfStudy'.tr,
                      value: _selectedYear,
                      errorText: _yearError,
                      isDark: isDark,
                      onTap: _openYearSelector,
                    ),

                    const SizedBox(height: 22),

                    // ── SECTION 3: Contact Information ───────────────────
                    _buildSectionHeader('community.contactInformation'.tr, isDark),
                    const SizedBox(height: 10),

                    _buildModernTextField(
                      label: 'community.emailReq'.tr,
                      hint: 'community.enterEmail'.tr,
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      isDark: isDark,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildModernTextField(
                      label: 'community.phoneNumberReq'.tr,
                      hint: 'community.enterPhoneNumber'.tr,
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      errorText: _phoneError,
                      isDark: isDark,
                      onChanged: (_) {
                        if (_phoneError != null) {
                          setState(() => _phoneError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── SECTION 4: Terms & Conditions Agreement ─────────
                    InkWell(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                          if (_agreedToTerms) _termsError = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: isDark
                                    ? AppColors.communityAccent
                                    : const Color(0xFF6D28D9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _agreedToTerms = val ?? false;
                                    if (_agreedToTerms) _termsError = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'community.iAgreeTerms'.tr,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showTermsModal(context),
                                    child: Text(
                                      'community.termsAndConditions'.tr,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.communityAccent
                                            : const Color(0xFF6D28D9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_termsError != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 34, top: 4),
                        child: Text(
                          _termsError!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Fixed Bottom Register Button ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: BoxDecoration(
                color: bgPrimary,
                border: Border(top: BorderSide(color: borderSubtle)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting || isAlreadyRegistered ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyRegistered
                        ? (isDark ? Colors.white12 : Colors.grey.shade300)
                        : (isDark ? Colors.white : Colors.black),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'community.registering'.tr,
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isAlreadyRegistered
                              ? 'community.alreadyRegistered'.tr
                              : 'community.registerNow'.tr,
                          style: TextStyle(
                            color: isAlreadyRegistered
                                ? (isDark ? Colors.white38 : Colors.grey.shade600)
                                : (isDark ? Colors.black : Colors.white),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Section Label ───────────────────────────────────────────────
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: isDark ? Colors.white54 : AppColors.lightTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Event Summary Card ─────────────────────────────────────────────────
  Widget _buildEventSummaryCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.event.coverImageFile != null
                ? Image.file(
                    widget.event.coverImageFile!,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                  )
                : widget.event.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.event.imageUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 58,
                          height: 58,
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                          child: Icon(Icons.event_outlined, color: textMuted, size: 24),
                        ),
                      )
                    : Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.event_outlined, color: textMuted, size: 24),
                      ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.event.dateString.isNotEmpty)
                  Row(
                    children: [
                      const Text(
                        '📅 ',
                        style: TextStyle(fontSize: 11),
                      ),
                      Expanded(
                        child: Text(
                          '${widget.event.dateString}${widget.event.timeString.isNotEmpty ? ' · ${widget.event.timeString}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      widget.event.eventType == 'Online' ? '🌐 ' : '📍 ',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Expanded(
                      child: Text(
                        widget.event.eventType == 'Online'
                            ? 'community.online'.tr
                            : (widget.event.location.isNotEmpty ? widget.event.location : 'community.phnomPenh'.tr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Modern Text Input Field ────────────────────────────────────────────
  Widget _buildModernTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final inputBg = isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? Colors.white12 : AppColors.lightBorderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : AppColors.lightTextMuted,
              fontSize: 13.5,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? const Color(0xFFEF4444) : borderSubtle,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? const Color(0xFFEF4444) : borderSubtle,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : (isDark ? Colors.white70 : Colors.black87),
                width: 1.4,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 13),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Modern Selector Tile (Dropdown replacement) ────────────────────────
  Widget _buildModernSelectorTile({
    required String label,
    required String placeholder,
    required String? value,
    required String? errorText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final inputBg = isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? Colors.white12 : AppColors.lightBorderSubtle;

    final isSelected = value != null && value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null ? const Color(0xFFEF4444) : borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isSelected ? value : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? textPrimary
                          : (isDark ? Colors.white30 : AppColors.lightTextMuted),
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: isDark ? Colors.white38 : AppColors.lightTextMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 13),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
