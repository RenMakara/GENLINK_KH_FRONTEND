import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/opportunity_model.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_design_tokens.dart';

class OpportunityDetailsScreen extends StatefulWidget {
  final OpportunityModel? opportunity;
  final String? opportunityId;
  final String? initialTitle;

  const OpportunityDetailsScreen({
    super.key,
    this.opportunity,
    this.opportunityId,
    this.initialTitle,
  });

  @override
  State<OpportunityDetailsScreen> createState() =>
      _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> {
  OpportunityModel? _opportunity;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
    if (_opportunity == null && widget.opportunityId != null) {
      _loadOpportunity();
    }
  }

  Future<void> _loadOpportunity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final controller = Get.find<CommunityController>();
      final result = await controller.repository.getOpportunityDetails(
        widget.opportunityId!,
      );
      if (mounted) {
        setState(() {
          _opportunity = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load opportunity details';
        });
      }
    }
  }

  Color _getTypeColor(String type) {
    final upper = type.toUpperCase();
    switch (upper) {
      case 'INTERNSHIP':
        return const Color(0xFF2563EB);
      case 'SCHOLARSHIP':
        return const Color(0xFFD97706);
      case 'JOB':
      case 'FULL_TIME':
      case 'FULL-TIME':
        return const Color(0xFF059669);
      case 'HACKATHON':
        return const Color(0xFF7C3AED);
      case 'VOLUNTEER':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  Future<void> _applyNow() async {
    final link = _opportunity?.applyLink.trim();
    if (link == null || link.isEmpty) {
      AppNotificationBanner.showWarning(
        context: context,
        title: 'No Apply Link',
        message: 'No external application link was provided for this opportunity.',
      );
      return;
    }

    Uri uri;
    if (link.startsWith('http://') || link.startsWith('https://')) {
      uri = Uri.parse(link);
    } else if (link.contains('@')) {
      uri = Uri(scheme: 'mailto', path: link);
    } else {
      uri = Uri.parse('https://$link');
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        AppNotificationBanner.showWarning(
          context: context,
          title: 'Unable to open link',
          message: 'Could not open $link',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showWarning(
          context: context,
          title: 'Unable to open link',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightSurfacePrimary;
    final primaryText = isDark ? Colors.white : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final mutedText =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBorder =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final opp = _opportunity;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 58,
        titleSpacing: 0,
        title: Text(
          widget.initialTitle ?? 'Opportunity Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          if (opp != null)
            GetBuilder<CommunityController>(
              builder: (controller) {
                final isSaved = opp.savedByMe;
                final isSaving = controller
                    .opportunityBookmarkLoadingIds
                    .contains(opp.id);

                return SizedBox(
                  width: 44,
                  height: 44,
                  child: isSaving
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: isSaved ? AppColors.brandPrimary : primaryText,
                          ),
                          onPressed: () async {
                            final newSaved = await controller
                                .toggleOpportunityBookmark(opp.id);
                            if (mounted) {
                              setState(() {
                                _opportunity = _opportunity?.copyWith(
                                  savedByMe: newSaved,
                                );
                              });
                            }
                          },
                        ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, opp, isDark, primaryText, secondaryText, mutedText, cardBorder),
      bottomNavigationBar: opp != null ? _buildBottomBar(context, opp, isDark) : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    OpportunityModel? opp,
    bool isDark,
    Color primaryText,
    Color secondaryText,
    Color mutedText,
    Color cardBorder,
  ) {
    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: mutedText),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryText, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _loadOpportunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (opp == null) {
      return const SizedBox.shrink();
    }

    final typeColor = _getTypeColor(opp.type);
    final initialLetter = opp.organization.isNotEmpty
        ? opp.organization[0].toUpperCase()
        : (opp.title.isNotEmpty ? opp.title[0].toUpperCase() : 'O');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: CommunityCardStyle.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: typeColor.withValues(alpha: isDark ? 0.35 : 0.20),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initialLetter,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opp.organization.isNotEmpty
                                ? opp.organization
                                : 'GenLink Opportunity',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: isDark ? 0.18 : 0.10),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              opp.displayType,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  opp.title,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Info Pills Grid
                Row(
                  children: [
                    if (opp.location.isNotEmpty)
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: opp.location,
                          isDark: isDark,
                        ),
                      ),
                    if (opp.location.isNotEmpty) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        icon: opp.isExpired
                            ? Icons.timer_off_outlined
                            : Icons.calendar_today_outlined,
                        label: 'Deadline',
                        value: opp.isExpired ? 'Expired' : opp.formattedDeadline,
                        isDark: isDark,
                        highlight: opp.isExpiringSoon || opp.isExpired,
                        highlightColor: opp.isExpired
                            ? Colors.red
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Overview / Description Section
          Text(
            'About this Opportunity',
            style: TextStyle(
              color: primaryText,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: CommunityCardStyle.cardDecoration(context),
            child: Text(
              opp.description.isNotEmpty
                  ? opp.description
                  : 'No detailed description provided.',
              style: TextStyle(
                color: primaryText,
                fontSize: 14.5,
                height: 1.6,
                letterSpacing: -0.1,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Key Highlights / Snapshot Section
          Text(
            'Key Details',
            style: TextStyle(
              color: primaryText,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: CommunityCardStyle.cardDecoration(context),
            child: Column(
              children: [
                _buildRowDetail('Opportunity Category', opp.displayType, secondaryText, primaryText, cardBorder),
                _buildRowDetail('Organization', opp.organization.isNotEmpty ? opp.organization : 'Not specified', secondaryText, primaryText, cardBorder),
                _buildRowDetail('Location', opp.location.isNotEmpty ? opp.location : 'Phnom Penh / Online', secondaryText, primaryText, cardBorder),
                _buildRowDetail('Application Deadline', opp.formattedDeadline, secondaryText, primaryText, cardBorder),
                _buildRowDetail('Application Method', 'External Link', secondaryText, primaryText, Colors.transparent),
              ],
            ),
          ),

          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool highlight = false,
    Color? highlightColor,
  }) {
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight ? highlightColor : textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textMuted, fontSize: 10.5),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlight ? highlightColor : textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 13.5)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    OpportunityModel opp,
    bool isDark,
  ) {
    final isExpired = opp.isExpired;
    final surface = isDark ? AppColors.darkSurfacePrimary : Colors.white;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: isExpired ? null : _applyNow,
          style: ElevatedButton.styleFrom(
            backgroundColor: isExpired
                ? (isDark ? Colors.white12 : Colors.black12)
                : AppColors.brandPrimary,
            disabledBackgroundColor:
                isDark ? Colors.white12 : Colors.black12,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isExpired ? 'Application Closed' : 'Apply Now',
                style: TextStyle(
                  color: isExpired
                      ? (isDark ? Colors.white38 : Colors.black38)
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isExpired) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_outward_rounded, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
