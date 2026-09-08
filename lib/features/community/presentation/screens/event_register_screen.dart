import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../finance/domain/entities/finance_entities.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../finance/presentation/controllers/ewallet_controller.dart';
import '../../../finance/presentation/formatters/finance_money_formatter.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'event_success_screen.dart';

class EventRegisterScreen extends StatefulWidget {
  final EventModel event;

  const EventRegisterScreen({super.key, required this.event});

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
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Year 5',
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
      _universityError = _selectedUniversity == null
          ? 'community.universityRequired'.tr
          : null;
      _facultyError = _selectedFaculty == null
          ? 'community.facultyRequired'.tr
          : null;
      _yearError = _selectedYear == null ? 'community.yearRequired'.tr : null;

      if (email.isEmpty) {
        _emailError = 'community.emailRequired'.tr;
      } else if (!RegExp(
        r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,6}$',
      ).hasMatch(email)) {
        _emailError = 'community.invalidEmail'.tr;
      } else {
        _emailError = null;
      }

      final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (phone.isEmpty) {
        _phoneError = 'community.phoneRequired'.tr;
      } else if (digitsOnly.length < 8 || digitsOnly.length > 10) {
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

  /// Checks the selected wallet balance before asking the backend to RSVP.
  ///
  /// This is only a user-facing pre-check. The backend still owns the final
  /// debit and can reject a stale balance safely.
  Future<bool> _confirmPaidEvent() async {
    if (!widget.event.isPaid || widget.event.price <= 0) {
      return true;
    }

    // Keep RSVP usable for an older shell that has not registered Finance yet;
    // the backend remains authoritative in that case.
    if (!Get.isRegistered<FinanceRepository>()) {
      return true;
    }

    final currency = widget.event.currency;
    final fee = widget.event.price;
    final repository = Get.find<FinanceRepository>();

    try {
      final wallet = await repository.getWallet();
      if (!mounted) return false;

      final balance = currency == FinanceCurrency.usd
          ? wallet.balanceUsd
          : wallet.balanceKhr;
      final feeLabel = FinanceMoneyFormatter.format(fee, currency);
      final balanceLabel = FinanceMoneyFormatter.format(balance, currency);

      if (balance < fee) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient ${currency.apiValue} wallet balance. '
              'Need $feeLabel, available $balanceLabel.',
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }

      final afterLabel = FinanceMoneyFormatter.format(balance - fee, currency);
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
          final textPrimary = isDark ? Colors.white : Colors.black87;
          final textSecondary = isDark ? Colors.white70 : Colors.black54;

          return AlertDialog(
            title: Text(
              'Confirm payment',
              style: TextStyle(color: textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This paid event will use your ${currency.apiValue} wallet.',
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Registration fee  $feeLabel',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Balance after RSVP  $afterLabel',
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Demo wallet payment',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Pay & RSVP'),
              ),
            ],
          );
        },
      );
      return confirmed == true;
    } on AppError catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to check your wallet balance.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  String _registrationErrorMessage(Object error) {
    if (error is AppError) {
      switch (error.errorCode) {
        case 'DEMO_WALLET_INSUFFICIENT_BALANCE':
          return 'Your ${widget.event.currency.apiValue} wallet balance is not enough for this event.';
        case 'DEMO_WALLET_NOT_FOUND':
          return 'Please open your wallet before joining a paid event.';
        case 'EVENT_CURRENCY_MISSING':
          return 'This event has no valid payment currency configured.';
        default:
          if (error.message.trim().isNotEmpty) return error.message;
      }
    }
    return 'Unable to complete registration. Please try again.';
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    // Dismiss active keyboard
    FocusScope.of(context).unfocus();

    if (!_validateForm()) {
      HapticFeedback.lightImpact();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (widget.event.isRsvped) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community.alreadyRegistered'.tr.isNotEmpty &&
                    'community.alreadyRegistered'.tr !=
                        'community.alreadyRegistered'
                ? 'community.alreadyRegistered'.tr
                : 'You are already registered for this event.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      if (!await _confirmPaidEvent()) {
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      final ctrl = Get.isRegistered<CommunityController>()
          ? Get.find<CommunityController>()
          : Get.put(CommunityController());
      final result = await ctrl.registerForEvent(
        widget.event.id,
        EventRegistrationInput(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          university: _selectedUniversity!,
          faculty: _selectedFaculty!,
          studyYear: _selectedYear!,
          termsAccepted: _agreedToTerms,
        ),
      );

      if (!mounted) return;

      // The backend is authoritative for both RSVP state and attendee count.
      widget.event.isRsvped = result.status.toUpperCase() == 'JOINED';
      widget.event.attendeesCount = result.attendeeCount;

      // Refresh an already-open wallet screen after the backend confirms the
      // debit. No local balance arithmetic is used as an authority.
      if (widget.event.isPaid && Get.isRegistered<EWalletController>()) {
        await Get.find<EWalletController>().loadWallet();
      }

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EventSuccessScreen(event: widget.event, result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_registrationErrorMessage(e)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openUniversitySelector() {
    _showSearchableSelectorSheet(
      title: 'community.selectUniversity'.tr,
      searchHint: 'community.searchUniversity'.tr,
      emptyMessage: 'community.noUniversityFound'.tr,
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
      emptyMessage: 'community.noFacultyFound'.tr,
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
      searchHint: '',
      emptyMessage: '',
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
    required String emptyMessage,
    required List<String> items,
    required String? selectedItem,
    required ValueChanged<String> onSelected,
    bool isSearchable = true,
  }) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;
    final textMuted = isDark ? Colors.white38 : AppColors.lightTextMuted;
    final borderSubtle = isDark ? Colors.white12 : AppColors.lightBorderSubtle;
    final searchBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.lightBgSecondary;
    final selectedTileBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

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
                : items
                      .where(
                        (i) => i.toLowerCase().contains(
                          query.toLowerCase().trim(),
                        ),
                      )
                      .toList();

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.80,
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
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

                    // Title Bar + Close Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: textSecondary,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // Search Field (if enabled)
                    if (isSearchable) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: searchBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: TextField(
                            style: TextStyle(color: textPrimary, fontSize: 14),
                            onChanged: (val) =>
                                setSheetState(() => query = val),
                            decoration: InputDecoration(
                              hintText: searchHint,
                              hintStyle: TextStyle(
                                color: textMuted,
                                fontSize: 13.5,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: textMuted,
                                size: 19,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // List or Empty Search Result
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 36,
                                horizontal: 20,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      color: textMuted,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      emptyMessage,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: borderSubtle.withValues(alpha: 0.5),
                              ),
                              itemBuilder: (context, idx) {
                                final item = filtered[idx];
                                final isSelected = item == selectedItem;

                                return InkWell(
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.pop(ctx);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? selectedTileBg
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.check_rounded,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            size: 20,
                                          ),
                                        ],
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
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;

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
                    backgroundColor: isDark ? Colors.white : Colors.black87,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'community.understand'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;
    final textMuted = isDark ? Colors.white54 : AppColors.lightTextMuted;
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? Colors.white12 : AppColors.lightBorderSubtle;

    // Check if already registered
    final isAlreadyRegistered = widget.event.isRsvped;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
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
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 20),

                    // If already registered, show informative banner
                    if (isAlreadyRegistered) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF22C55E),
                              size: 22,
                            ),
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
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.lightTextSecondary,
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
                    _buildSectionHeader(
                      'community.academicInformation'.tr,
                      isDark,
                    ),
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
                      placeholder: 'community.selectYear'.tr,
                      value: _selectedYear,
                      errorText: _yearError,
                      isDark: isDark,
                      onTap: _openYearSelector,
                    ),

                    const SizedBox(height: 22),

                    // ── SECTION 3: Contact Information ───────────────────
                    _buildSectionHeader(
                      'community.contactInformation'.tr,
                      isDark,
                    ),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
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
                                    ? Colors.white
                                    : Colors.black87,
                                checkColor: isDark
                                    ? Colors.black
                                    : Colors.white,
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
                                        color: textPrimary,
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
                  onPressed: _isSubmitting || isAlreadyRegistered
                      ? null
                      : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadyRegistered
                        ? (isDark ? Colors.white12 : Colors.grey.shade300)
                        : (isDark ? Colors.white : Colors.black87),
                    foregroundColor: isAlreadyRegistered
                        ? (isDark ? Colors.white38 : Colors.grey.shade600)
                        : (isDark ? Colors.black : Colors.white),
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
                                ? (isDark
                                      ? Colors.white38
                                      : Colors.grey.shade600)
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
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    return Text(
      title,
      style: TextStyle(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Compact Event Summary Card ─────────────────────────────────────────
  Widget _buildEventSummaryCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final isOnline = widget.event.eventType.toLowerCase().contains('online');
    final String locationDisplay = isOnline
        ? '🌐 ${'community.onlineEvent'.tr}'
        : '📍 ${widget.event.location.isNotEmpty ? widget.event.location : 'community.inPerson'.tr}';

    final String dateDisplay = widget.event.timeString.isNotEmpty
        ? '📅 ${widget.event.dateString} · ${widget.event.timeString}'
        : (widget.event.dateString.isNotEmpty
              ? '📅 ${widget.event.dateString}'
              : '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: _buildEventThumbnail(isDark, textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    height: 1.25,
                  ),
                ),
                if (dateDisplay.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  locationDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventThumbnail(bool isDark, Color textMuted) {
    if (widget.event.coverImageFile != null) {
      return Image.file(
        widget.event.coverImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _eventThumbnailPlaceholder(isDark, textMuted),
      );
    }
    if (widget.event.imageUrl.isNotEmpty) {
      return Image.network(
        widget.event.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: isDark ? const Color(0xFF1E2228) : const Color(0xFFE9ECF0),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _eventThumbnailPlaceholder(isDark, textMuted),
      );
    }
    return _eventThumbnailPlaceholder(isDark, textMuted);
  }

  Widget _eventThumbnailPlaceholder(bool isDark, Color textMuted) {
    return Container(
      color: isDark ? const Color(0xFF1E2228) : const Color(0xFFE9ECF0),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          color: textMuted.withValues(alpha: 0.6),
          size: 24,
        ),
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
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;
    final inputBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? Colors.white12 : AppColors.lightBorderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : borderSubtle,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : borderSubtle,
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
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11.5,
                    ),
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
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;
    final inputBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.lightBgSecondary;
    final borderSubtle = isDark ? Colors.white12 : AppColors.lightBorderSubtle;

    final isSelected = value != null && value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
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
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : borderSubtle,
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
                          : (isDark
                                ? Colors.white30
                                : AppColors.lightTextMuted),
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
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
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11.5,
                    ),
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
