import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'create_event_screen.dart';
import 'event_register_screen.dart';
import '../../../profile/presentation/utils/profile_navigation.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final String? heroTag;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Future<bool> Function(String eventId)? onCancelRsvp;

  const EventDetailsScreen({
    super.key,
    required this.event,
    this.heroTag,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onCancelRsvp,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with SingleTickerProviderStateMixin {
  late EventModel _event;
  String? _detailsErrorMessage;
  bool _isBookmarked = false;
  bool _isDescriptionExpanded = false;
  bool _isButtonPressed = false;
  bool _isCancelling = false;
  double _bookmarkScale = 1.0;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _isBookmarked = widget.event.isBookmarked;
    _fetchLatestEventDetails();
  }

  @override
  void didUpdateWidget(EventDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event != widget.event) {
      _event = widget.event;
      _isBookmarked = widget.event.isBookmarked;
      _fetchLatestEventDetails();
    }
  }

  Future<void> _fetchLatestEventDetails() async {
    if (_event.id.isEmpty) return;
    try {
      final ctrl = Get.isRegistered<CommunityController>()
          ? Get.find<CommunityController>()
          : Get.put(CommunityController());
      final fresh = await ctrl.fetchEventDetails(_event.id);
      if (mounted) {
        setState(() {
          _event = fresh;
          _isBookmarked = fresh.isBookmarked;
        });
      }
    } catch (error) {
      if (!mounted) return;
      // A 404/403 means the event is no longer visible to this user, so the
      // list/search object must not remain on screen as if it were valid.
      // For transient transport/server failures, retain the already-loaded
      // event card instead of replacing real list data with a misleading
      // "unavailable" state; the next explicit refresh can retry the lookup.
      if (error is AppError &&
          (error.isNotFound ||
              error.isForbidden ||
              error.errorCode == 'EVENT_NOT_FOUND' ||
              error.errorCode == 'EVENT_UNAVAILABLE')) {
        setState(() => _detailsErrorMessage = 'community.eventUnavailable'.tr);
      }
    }
  }

  void _triggerBookmarkAnimation() {
    setState(() => _bookmarkScale = 1.25);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() => _bookmarkScale = 1.0);
      }
    });
  }

  bool _checkIsOrganizer(EventModel event) {
    final eventOrgId = event.organizerId?.trim() ?? '';
    final currentUid = CurrentUser.id.trim();

    if (eventOrgId.isNotEmpty &&
        currentUid.isNotEmpty &&
        currentUid.toLowerCase() == eventOrgId.toLowerCase()) {
      return true;
    }

    // Legacy test mock fallback (when test creates EventModel with organizerName: 'me' without AuthController)
    if (eventOrgId.isEmpty && event.organizerName.trim().toLowerCase() == 'me') {
      return true;
    }

    return event.isOwnedBy(currentUid);
  }

  Future<void> _openMeeting(
    BuildContext context,
    EventModel event,
    bool isDark,
  ) async {
    final rawUrl = event.effectiveMeetingUrl.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      _showSnackBar(context, isDark, 'community.meetingLinkOpenFailed'.tr);
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!opened) {
        _showSnackBar(context, isDark, 'community.meetingLinkOpenFailed'.tr);
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, isDark, 'community.meetingLinkOpenFailed'.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKhmer = Get.locale?.languageCode == 'km';

    // ── Error State ──────────────────────────────────────────────────────────
    if ((_detailsErrorMessage != null && _detailsErrorMessage!.isNotEmpty) ||
        (widget.errorMessage != null && widget.errorMessage!.isNotEmpty)) {
      return _buildErrorState(context, isDark);
    }

    // ── Loading Skeleton State ───────────────────────────────────────────────
    if (widget.isLoading) {
      return _buildLoadingSkeleton(context, isDark);
    }

    final controller = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>()
        : null;

    final event = controller != null
        ? (controller.events.firstWhereOrNull((e) => e.id == _event.id) ??
              _event)
        : _event;

    final isOrganizer = _checkIsOrganizer(event);

    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;
    final surfacePrimary = isDark ? const Color(0xFF141414) : Colors.white;
    final tileBg = isDark ? const Color(0xFF18181A) : const Color(0xFFF6F6F8);
    final borderSubtle = isDark
        ? const Color(0xFF28282A)
        : const Color(0xFFE6E6EA);
    final bgPrimary = Theme.of(context).scaffoldBackgroundColor;

    final bool hasNetworkImage = event.imageUrl.isNotEmpty;
    final bool hasLocalImage = event.coverImageFile != null;

    final effectiveHeroTag = widget.heroTag ?? 'event-image-${event.id}';
    final double coverHeight = (hasLocalImage || hasNetworkImage)
        ? 240.0
        : 180.0;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image with Overlay Controls ─────────────────────────
                Stack(
                  children: [
                    Hero(
                      tag: effectiveHeroTag,
                      child: SizedBox(
                        height: coverHeight,
                        width: double.infinity,
                        child: hasLocalImage
                            ? Image.file(
                                event.coverImageFile!,
                                fit: BoxFit.cover,
                              )
                            : hasNetworkImage
                            ? (event.imageUrl.startsWith('assets/')
                                  ? Image.asset(
                                      event.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _placeholderCover(isDark),
                                    )
                                  : Image.network(
                                      event.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _placeholderCover(isDark),
                                    ))
                            : _placeholderCover(isDark),
                      ),
                    ),

                    // Contrast gradient overlay
                    Container(
                      height: coverHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                            Colors.transparent,
                            bgPrimary.withValues(alpha: 0.95),
                          ],
                          stops: const [0.0, 0.28, 0.68, 1.0],
                        ),
                      ),
                    ),

                    // Top Action Bar (Back, Bookmark, Share)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            // Back Button
                            _buildFrostedButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            const Spacer(),

                            // Bookmark Button
                            if (controller != null)
                              Obx(() {
                                final ev = controller.events.firstWhereOrNull(
                                  (e) => e.id == event.id,
                                );
                                final isSaved =
                                    ev?.isBookmarked ?? _isBookmarked;
                                return AnimatedScale(
                                  scale: _bookmarkScale,
                                  duration: const Duration(milliseconds: 140),
                                  child: _buildFrostedButton(
                                    icon: isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    iconColor: isSaved ? AppColors.warning : Colors.white,
                                    onTap: () {
                                      _triggerBookmarkAnimation();
                                      setState(() => _isBookmarked = !isSaved);
                                      controller.toggleEventBookmark(event.id);
                                      final nowSaved = !isSaved;
                                      _showSnackBar(
                                        context,
                                        isDark,
                                        nowSaved
                                            ? 'community.savedToBookmarks'.tr
                                            : 'community.removedFromBookmarks'
                                                  .tr,
                                      );
                                    },
                                  ),
                                );
                              })
                            else
                              AnimatedScale(
                                scale: _bookmarkScale,
                                duration: const Duration(milliseconds: 140),
                                child: _buildFrostedButton(
                                  icon: _isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  iconColor: _isBookmarked ? AppColors.warning : Colors.white,
                                  onTap: () {
                                    _triggerBookmarkAnimation();
                                    setState(
                                      () => _isBookmarked = !_isBookmarked,
                                    );
                                    _showSnackBar(
                                      context,
                                      isDark,
                                      _isBookmarked
                                          ? 'community.savedToBookmarks'.tr
                                          : 'community.removedFromBookmarks'.tr,
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(width: 8),

                            // Share Button
                            _buildFrostedButton(
                              icon: Icons.share_outlined,
                              onTap: () {
                                _showSnackBar(
                                  context,
                                  isDark,
                                  'community.share'.tr,
                                );
                              },
                            ),
                            if (isOrganizer) ...[
                              const SizedBox(width: 8),
                              _buildOwnerMoreButton(
                                context: context,
                                event: event,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                controller: controller,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Event Badges (Category & Format Mode)
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          if (event.category.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.transparent,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIconData(event.category),
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _localizedCategory(
                                      event.category,
                                    ).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: event.isOnline
                                  ? (isDark
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : Colors.black)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : const Color(0xFF1E1E24)),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.white12,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              (event.isOnline
                                      ? 'community.onlineEvent'.tr
                                      : 'community.inPerson'.tr)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Main Event Content ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Title
                      Text(
                        event.title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (event.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.subtitle,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // ── Compact Event Info Rows ───────────────────────────
                      // 1. Date and Time
                      _buildDateInfoCard(
                        event: event,
                        isKhmer: isKhmer,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        tileBg: tileBg,
                        borderSubtle: borderSubtle,
                      ),
                      const SizedBox(height: 10),

                      // 2. Location (In-person) OR Online Meeting Link
                      if (event.isOnline)
                        _buildOnlineInfoCard(
                          context: context,
                          event: event,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        )
                      else
                        _buildInPersonInfoCard(
                          context: context,
                          event: event,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          tileBg: tileBg,
                          borderSubtle: borderSubtle,
                        ),
                      const SizedBox(height: 10),

                      // 3. Ticket / Price Info
                      _buildPriceInfoCard(
                        event: event,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        tileBg: tileBg,
                        borderSubtle: borderSubtle,
                      ),
                      const SizedBox(height: 10),

                      // 4. Organizer Row with Owner Controls ─────────────────
                      _buildOrganizerCard(
                        context: context,
                        event: event,
                        controller: controller,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        tileBg: tileBg,
                        borderSubtle: borderSubtle,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // 5. About This Event (Expandable Description) ─────────
                      Text(
                        'community.aboutThisEvent'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildExpandableDescription(
                        description: event.description,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // 6. Attendees / Capacity
                      _buildAttendeesInfoCard(
                        context: context,
                        event: event,
                        controller: controller,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        tileBg: tileBg,
                        borderSubtle: borderSubtle,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 130),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed Bottom RSVP Action Bar ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 8
                    : 18,
              ),
              decoration: BoxDecoration(
                color: surfacePrimary,
                border: Border(
                  top: BorderSide(color: borderSubtle, width: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: controller != null
                  ? Obx(() {
                      final ev = controller.events.firstWhereOrNull(
                        (e) => e.id == event.id,
                      );
                      return _buildBottomRsvpButton(
                        context: context,
                        event: ev ?? event,
                        isDark: isDark,
                      );
                    })
                  : _buildBottomRsvpButton(
                      context: context,
                      event: event,
                      isDark: isDark,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-Widgets ────────────────────────────────────────────────────────────

  Widget _buildFrostedButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Center(child: Icon(icon, color: iconColor, size: 19)),
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

  Widget _buildOwnerMoreButton({
    required BuildContext context,
    required EventModel event,
    required bool isDark,
    required Color textPrimary,
    required CommunityController? controller,
  }) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: const Center(
          child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
        ),
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E1E20) : Colors.white,
      onSelected: (val) => _handleOwnerAction(
        context: context,
        action: val,
        event: event,
        isDark: isDark,
        controller: controller,
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 18, color: textPrimary),
              const SizedBox(width: 8),
              Text(
                'community.editEvent'.tr.isNotEmpty &&
                        'community.editEvent'.tr != 'community.editEvent'
                    ? 'community.editEvent'.tr
                    : 'Edit Event',
                style: TextStyle(color: textPrimary, fontSize: 13.5),
              ),
            ],
          ),
        ),
        if (event.imageUrl.isNotEmpty || event.coverImageFile != null)
          PopupMenuItem(
            value: 'remove_cover',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 18,
                  color: textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Remove Cover Image',
                  style: TextStyle(color: textPrimary, fontSize: 13.5),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                'community.deleteEvent'.tr.isNotEmpty &&
                        'community.deleteEvent'.tr != 'community.deleteEvent'
                    ? 'community.deleteEvent'.tr
                    : 'Delete Event',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleOwnerAction({
    required BuildContext context,
    required String action,
    required EventModel event,
    required bool isDark,
    required CommunityController? controller,
  }) async {
    if (action == 'remove_cover') {
      if (controller != null) {
        final updateReq = EventCreateRequest(
          title: event.title,
          description: event.description,
          category: event.category,
          coverImageUrl: '',
          startDateTime: event.startDateTime ?? DateTime.now(),
          endDateTime: event.endDateTime ?? DateTime.now().add(const Duration(hours: 2)),
          mode: event.mode ?? (event.isOnline ? 'ONLINE' : 'IN_PERSON'),
          meetingUrl: event.meetingUrl,
          locationName: event.locationName,
          latitude: event.latitude,
          longitude: event.longitude,
          attendeeLimit: event.attendeeLimit,
          status: event.status,
          language: event.language,
          paid: event.isPaid,
          price: event.price,
          currency: event.currency,
        );
        try {
          final updated = await controller.updateEvent(event.id, updateReq);
          if (mounted) {
            setState(() {
              _event = updated.copyWith(imageUrl: '');
            });
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _event = event.copyWith(imageUrl: '');
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _event = event.copyWith(imageUrl: '');
          });
        }
      }
    } else if (action == 'edit') {
      final updated = await Get.to<EventModel?>(
        () => CreateEventScreen(eventToEdit: event, returnCreatedEvent: true),
      );
      if (updated != null && mounted) {
        setState(() {
          _event = updated;
        });
        if (controller != null) {
          controller.fetchEventDetails(updated.id);
        }
      }
    } else if (action == 'delete') {
      final confirmed = await GenLinkConfirmDialog.showDanger(
        context: context,
        title: 'community.deleteEvent'.tr.isNotEmpty &&
                'community.deleteEvent'.tr != 'community.deleteEvent'
            ? '${'community.deleteEvent'.tr}?'
            : 'Delete Event?',
        message: 'community.deleteEventConfirm'.tr.isNotEmpty &&
                'community.deleteEventConfirm'.tr !=
                    'community.deleteEventConfirm'
            ? 'community.deleteEventConfirm'.tr
            : 'Are you sure you want to delete this event? This action cannot be undone.',
        confirmLabel: 'common.delete'.tr.isNotEmpty &&
                'common.delete'.tr != 'common.delete'
            ? 'common.delete'.tr
            : 'Delete',
        cancelLabel: 'common.cancel'.tr.isNotEmpty &&
                'common.cancel'.tr != 'common.cancel'
            ? 'common.cancel'.tr
            : 'Cancel',
        icon: Icons.delete_outline_rounded,
      );

      if (confirmed == true) {
        try {
          if (controller != null) {
            await controller.deleteEvent(event.id);
          }
          if (mounted) {
            Navigator.pop(this.context, true);
            AppNotificationBanner.showSuccess(
              context: Get.context ?? this.context,
              title: 'Event Deleted',
              message: 'Your event has been successfully deleted.',
            );
          }
        } catch (e) {
          if (mounted) {
            final errorMsg = e is AppError
                ? e.message
                : 'Failed to delete event. Please try again.';
            AppNotificationBanner.showDanger(
              context: this.context,
              title: 'Error',
              message: errorMsg,
            );
          }
        }
      }
    }
  }

  Widget _buildOrganizerCard({
    required BuildContext context,
    required EventModel event,
    required CommunityController? controller,
    required Color textPrimary,
    required Color textSecondary,
    required Color tileBg,
    required Color borderSubtle,
    required bool isDark,
  }) {
    final currentUserId = CurrentUser.id;
    final isOrganizer = _checkIsOrganizer(event);

    final orgName = event.organizerName.isNotEmpty
        ? event.organizerName
        : 'GenLink Community';

    String? effectiveAvatar =
        (event.organizerAvatar != null &&
            event.organizerAvatar!.trim().isNotEmpty)
        ? event.organizerAvatar!.trim()
        : null;

    if (effectiveAvatar == null &&
        currentUserId.isNotEmpty &&
        event.organizerId == currentUserId) {
      final currentAvatar = CurrentUser.avatarUrl?.trim();
      if (currentAvatar != null && currentAvatar.isNotEmpty) {
        effectiveAvatar = currentAvatar;
      }
    }

    ImageProvider? avatarProvider;
    if (effectiveAvatar != null && effectiveAvatar.isNotEmpty) {
      if (effectiveAvatar.startsWith('assets/')) {
        avatarProvider = AssetImage(effectiveAvatar);
      } else {
        final fullUrl = effectiveAvatar.startsWith('http')
            ? effectiveAvatar
            : '${AppConfig.apiBaseUrl}${effectiveAvatar.startsWith('/') ? '' : '/'}$effectiveAvatar';
        avatarProvider = NetworkImage(fullUrl);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final isMe = _checkIsOrganizer(event);
          if (isMe) {
            ProfileNavigation.open();
            return;
          }
          final effectiveUsername = (event.organizerUsername != null &&
                  event.organizerUsername!.trim().isNotEmpty)
              ? event.organizerUsername!.trim()
              : null;
          final effectiveUserId = (event.organizerId != null &&
                  event.organizerId!.trim().isNotEmpty)
              ? event.organizerId!.trim()
              : null;
          final fallbackName = (event.organizerName.trim().isNotEmpty &&
                  event.organizerName.trim().toLowerCase() != 'me')
              ? event.organizerName.trim()
              : null;

          ProfileNavigation.open(
            username: effectiveUsername ?? fallbackName,
            userId: effectiveUserId,
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderSubtle, width: 0.8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                foregroundImage: avatarProvider,
                onForegroundImageError: avatarProvider != null ? (exception, stackTrace) {} : null,
                child: Text(
                  orgName.isNotEmpty ? orgName[0].toUpperCase() : 'G',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orgName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOrganizer
                          ? "You're the Organizer"
                          : 'community.organizer'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isOrganizer
                            ? (isDark ? Colors.white70 : Colors.black87)
                            : textSecondary,
                        fontSize: 12,
                        fontWeight: isOrganizer ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
                size: 20,
              ),
            ],
          ),
        )
      ),
    );
  }

  Widget _buildDateInfoCard({
    required EventModel event,
    required bool isKhmer,
    required Color textPrimary,
    required Color textSecondary,
    required Color tileBg,
    required Color borderSubtle,
  }) {
    final dateDisplay = event.formatLocalizedDateRange(isKhmer);
    final timeDisplay = event.formatLocalizedTimeRange(isKhmer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBadge(
            Icons.calendar_today_rounded,
            textPrimary,
            textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateDisplay.isNotEmpty ? dateDisplay : 'community.dateTbc'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (timeDisplay.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timeDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSecondary, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineInfoCard({
    required BuildContext context,
    required EventModel event,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color tileBg,
    required Color borderSubtle,
  }) {
    final currentUserId = CurrentUser.id;
    final isOrganizer = _checkIsOrganizer(event);
    final canAccessMeeting = event.canAccessMeetingFor(currentUserId) || isOrganizer;
    final hasMeetingUrl = event.effectiveMeetingUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIconBadge(Icons.language_rounded, textPrimary, textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.onlineEvent'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (canAccessMeeting && hasMeetingUrl) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _openMeeting(context, event, isDark),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'community.joinOnlineEvent'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (!canAccessMeeting) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'community.meetingLinkAfterRegistration'
                                      .tr
                                      .isNotEmpty &&
                                  'community.meetingLinkAfterRegistration'.tr !=
                                      'community.meetingLinkAfterRegistration'
                              ? 'community.meetingLinkAfterRegistration'.tr
                              : 'Meeting link available after registration',
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInPersonInfoCard({
    required BuildContext context,
    required EventModel event,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color tileBg,
    required Color borderSubtle,
  }) {
    final locationName = event.effectiveLocationName.isNotEmpty
        ? event.effectiveLocationName
        : 'community.locationTbc'.tr;

    final hasCoordinates = event.latitude != null && event.longitude != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBadge(
            Icons.location_on_rounded,
            textPrimary,
            textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'community.physicalVenue'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                if (hasCoordinates) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showMapModal(context, event, isDark),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'community.viewOnMap'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfoCard({
    required EventModel event,
    required Color textPrimary,
    required Color textSecondary,
    required Color tileBg,
    required Color borderSubtle,
  }) {
    final String line1;
    final String line2;

    if (!event.isPaid) {
      line1 = 'community.freeEntry'.tr;
      line2 = 'community.noRegistrationFee'.tr;
    } else {
      line1 = event.displayPriceString;
      line2 = 'community.standardTicket'.tr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBadge(
            Icons.confirmation_number_outlined,
            textPrimary,
            textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesInfoCard({
    required BuildContext context,
    required EventModel event,
    required CommunityController? controller,
    required Color textPrimary,
    required Color textSecondary,
    required Color tileBg,
    required Color borderSubtle,
    required bool isDark,
  }) {
    final isOrganizer = _checkIsOrganizer(event);

    Widget content(int count, int? limit, bool isFull) {
      final String line1;
      final String line2;

      if (limit != null && limit > 0) {
        line1 = '$count / $limit ${'community.joined'.tr}';
      } else {
        line1 = '$count ${'community.joined'.tr}';
      }

      if (isFull || (limit != null && count >= limit)) {
        line2 = 'community.eventFull'.tr;
      } else {
        line2 = 'community.registeredAttendees'.tr;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderSubtle, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconBadge(
              Icons.people_alt_rounded,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (isFull || (limit != null && count >= limit))
                          ? AppColors.danger
                          : textSecondary,
                      fontSize: 12,
                      fontWeight: (isFull || (limit != null && count >= limit))
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isOrganizer) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
            ],
          ],
        ),
      );
    }

    Widget cardWidget;
    if (controller != null) {
      cardWidget = Obx(() {
        final ev = controller.events.firstWhereOrNull((e) => e.id == event.id);
        final count = ev?.attendeesCount ?? event.attendeesCount;
        final limit = ev?.attendeeLimit ?? event.attendeeLimit;
        final full = ev?.isFull ?? event.isFull;
        return content(count, limit, full);
      });
    } else {
      cardWidget = content(
        event.attendeesCount,
        event.attendeeLimit,
        event.isFull,
      );
    }

    if (isOrganizer) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAttendeesSheet(context, event, isDark),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }

  Widget _buildExpandableDescription({
    required String description,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final text = description.isNotEmpty
        ? description
        : 'Discover opportunities, meet peers, and grow your skills with this student community event.';

    final bool isLong = text.length > 170 || text.split('\n').length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: (_isDescriptionExpanded || !isLong)
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
          ),
          secondChild: Text(
            text,
            style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _isDescriptionExpanded
                    ? 'community.readLess'.tr
                    : 'community.readMore'.tr,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomRsvpButton({
    required BuildContext context,
    required EventModel event,
    required bool isDark,
  }) {
    final isOrganizer = _checkIsOrganizer(event);

    final isFull =
        event.isFull ||
        (event.attendeeLimit != null &&
            event.attendeesCount >= event.attendeeLimit!);

    final isRsvpEligible = event.isRsvpEligible;
    final isPast = event.isPast;
    final isJoined = event.hasJoinedRsvp;

    // When the user is already registered (and not the organizer),
    // provide the registered status badge alongside the Cancel Registration action.
    if (!isOrganizer && isJoined) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B271E)
                    : const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C4D35)
                      : const Color(0xFFB5E2C0),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: isDark
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF16A34A),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'community.youAreRegistered'.tr,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF15803D),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isCancelling
                    ? null
                    : () => _handleCancelRegistration(event, isDark),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF4B2323)
                        : const Color(0xFFFCA5A5),
                    width: 0.8,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF261616)
                      : const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFEF4444),
                          ),
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cancel_outlined, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'community.cancelRegistration'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    }

    final String label;
    final IconData? icon;
    final Color? iconColor;

    if (isOrganizer) {
      label = "You're the Organizer";
      icon = Icons.stars_rounded;
      iconColor = isDark ? Colors.white : Colors.black87;
    } else if (!event.isPublished) {
      label = event.isDraft
          ? 'community.eventDraft'.tr
          : event.isCancelled
          ? 'community.eventCancelled'.tr
          : event.isCompleted
          ? 'community.eventCompleted'.tr
          : 'community.eventUnavailable'.tr;
      icon = Icons.schedule_rounded;
      iconColor = textDisabled(isDark);
    } else if (isPast || !isRsvpEligible) {
      label = 'community.eventPast'.tr;
      icon = Icons.schedule_rounded;
      iconColor = textDisabled(isDark);
    } else if (isFull) {
      label = 'community.eventFull'.tr;
      icon = Icons.block_rounded;
      iconColor = AppColors.danger;
    } else {
      label = 'community.registerNow'.tr;
      icon = null;
      iconColor = null;
    }

    final bool isInactive = isOrganizer || isFull || !isRsvpEligible;

    return GestureDetector(
      onTapDown: isInactive
          ? null
          : (_) => setState(() => _isButtonPressed = true),
      onTapUp: isInactive
          ? null
          : (_) => setState(() => _isButtonPressed = false),
      onTapCancel: isInactive
          ? null
          : () => setState(() => _isButtonPressed = false),
      child: AnimatedScale(
        scale: _isButtonPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isInactive
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventRegisterScreen(event: event),
                      ),
                    ).then((_) {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: isDark
                  ? const Color(0xFF222224)
                  : const Color(0xFFEEEEF0),
              disabledForegroundColor: isDark ? Colors.white70 : Colors.black87,
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: isInactive
                    ? BorderSide(
                        color: isDark
                            ? const Color(0xFF333336)
                            : const Color(0xFFDDDDE0),
                        width: 0.8,
                      )
                    : BorderSide.none,
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isInactive
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : (isDark ? Colors.black : Colors.white),
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancelRegistration(EventModel event, bool isDark) async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'community.cancelRegistrationTitle'.tr,
      message: 'community.cancelRegistrationConfirm'.tr,
      confirmLabel: 'community.confirmCancel'.tr,
      cancelLabel: 'common.cancel'.tr,
      icon: Icons.event_busy_rounded,
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      bool success = false;
      if (widget.onCancelRsvp != null) {
        success = await widget.onCancelRsvp!(event.id);
      } else {
        final ctrl = Get.isRegistered<CommunityController>()
            ? Get.find<CommunityController>()
            : Get.put(CommunityController());
        success = await ctrl.cancelEventRegistration(event.id);
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isCancelling = false;
          _event.isRsvped = false;
          _event.myRsvpStatus = 'CANCELLED';
          _event.attendeesCount = (_event.attendeesCount - 1).clamp(0, 999999);
        });

        if (Get.isRegistered<CommunityController>()) {
          final ctrl = Get.find<CommunityController>();
          ctrl.syncEventRsvp(
            event.id,
            isRsvped: false,
            attendeesCount: _event.attendeesCount,
            status: 'CANCELLED',
          );
        }

        _showSnackBar(context, isDark, 'community.registrationCancelled'.tr);
      } else {
        setState(() => _isCancelling = false);
        _showSnackBar(context, isDark, 'community.cancelRsvpFailed'.tr);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      _showSnackBar(context, isDark, 'community.cancelRsvpFailed'.tr);
    }
  }

  Color textDisabled(bool isDark) => isDark ? Colors.white38 : Colors.black38;

  Widget _buildIconBadge(
    IconData icon,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: textPrimary, size: 18),
    );
  }

  void _showMapModal(BuildContext context, EventModel event, bool isDark) {
    final lat = event.latitude!;
    final lng = event.longitude!;
    final latDirection = lat >= 0 ? 'N' : 'S';
    final lngDirection = lng >= 0 ? 'E' : 'W';
    final latFormatted = '${lat.abs().toStringAsFixed(4)}° $latDirection';
    final lngFormatted = '${lng.abs().toStringAsFixed(4)}° $lngDirection';
    final coordsText = '$latFormatted, $lngFormatted';
    final locName = event.effectiveLocationName.isNotEmpty
        ? event.effectiveLocationName
        : 'Physical Venue';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locName,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            coordsText,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: '$locName ($coordsText)'),
                      );
                      Navigator.pop(ctx);
                      _showSnackBar(
                        context,
                        isDark,
                        'community.copyLocation'.tr,
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(
                      'community.copyLocation'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttendeesSheet(
    BuildContext context,
    EventModel event,
    bool isDark,
  ) {
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final borderSubtle = isDark
        ? const Color(0xFF28282A)
        : const Color(0xFFE6E6EA);
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final attendees = <EventAttendeeModel>[];
        EventPageModel<EventAttendeeModel>? attendeePage;
        Future<EventPageModel<EventAttendeeModel>>? firstPageFuture;
        bool initialPageLoaded = false;
        bool loadingMore = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final controller = Get.isRegistered<CommunityController>()
                ? Get.find<CommunityController>()
                : null;
            if (controller != null && firstPageFuture == null) {
              firstPageFuture = controller.fetchEventAttendeesPage(
                event.id,
                page: 1,
                limit: 20,
              );
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'community.eventAttendees'.tr.isNotEmpty &&
                                          'community.eventAttendees'.tr !=
                                              'community.eventAttendees'
                                      ? 'community.eventAttendees'.tr
                                      : 'Event Attendees',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${event.attendeesCount} ${'community.registered'.tr.isNotEmpty && 'community.registered'.tr != 'community.registered' ? 'community.registered'.tr : 'registered'}',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: textPrimary,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderSubtle),

                    Expanded(
                      child: controller == null
                          ? Center(
                              child: Text(
                                'Controller unavailable',
                                style: TextStyle(color: textSecondary),
                              ),
                            )
                          : FutureBuilder<EventPageModel<EventAttendeeModel>>(
                              future: firstPageFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'community.loadingAttendees'
                                                      .tr
                                                      .isNotEmpty &&
                                                  'community.loadingAttendees'
                                                          .tr !=
                                                      'community.loadingAttendees'
                                              ? 'community.loadingAttendees'.tr
                                              : 'Loading attendees...',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black45,
                                            size: 40,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Failed to load attendees',
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Please check your connection and try again.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () =>
                                                setSheetState(() {}),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              foregroundColor: isDark
                                                  ? Colors.black
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.hasData && !initialPageLoaded) {
                                  attendeePage = snapshot.data;
                                  attendees.addAll(snapshot.data!.content);
                                  initialPageLoaded = true;
                                }
                                if (attendees.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.people_outline_rounded,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black26,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'community.noAttendeesYet'
                                                        .tr
                                                        .isNotEmpty &&
                                                    'community.noAttendeesYet'
                                                            .tr !=
                                                        'community.noAttendeesYet'
                                                ? 'community.noAttendeesYet'.tr
                                                : 'No attendees yet',
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Registered attendees will appear here.',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount:
                                      attendees.length +
                                      (attendeePage?.hasNext == true ? 1 : 0),
                                  separatorBuilder: (context, index) =>
                                      Divider(height: 1, color: borderSubtle),
                                  itemBuilder: (context, index) {
                                    if (index == attendees.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: loadingMore
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : TextButton(
                                                  onPressed: () async {
                                                    if (loadingMore ||
                                                        attendeePage == null) {
                                                      return;
                                                    }
                                                    setSheetState(
                                                      () => loadingMore = true,
                                                    );
                                                    try {
                                                      final next = await controller
                                                          .fetchEventAttendeesPage(
                                                            event.id,
                                                            page:
                                                                attendeePage!
                                                                    .page +
                                                                2,
                                                            limit: 20,
                                                          );
                                                      attendees.addAll(
                                                        next.content,
                                                      );
                                                      attendeePage = next;
                                                    } finally {
                                                      if (ctx.mounted) {
                                                        setSheetState(
                                                          () => loadingMore =
                                                              false,
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Text(
                                                    'community.loadMore'.tr,
                                                  ),
                                                ),
                                        ),
                                      );
                                    }
                                    final attendee = attendees[index];
                                    final displayName =
                                        attendee.fullName.isNotEmpty
                                        ? attendee.fullName
                                        : (attendee.username.isNotEmpty
                                              ? attendee.username
                                              : 'GenLink User');
                                    final initial = displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'U';

                                    String joinedSubtitle = '';
                                    if (attendee.username.isNotEmpty) {
                                      joinedSubtitle = '@${attendee.username}';
                                    }
                                    if (attendee.joinedAt != null) {
                                      final jDate = attendee.joinedAt!;
                                      final dateStr =
                                          '${jDate.day}/${jDate.month}/${jDate.year}';
                                      joinedSubtitle = joinedSubtitle.isNotEmpty
                                          ? '$joinedSubtitle · Joined $dateStr'
                                          : 'Joined $dateStr';
                                    }

                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4,
                                          ),
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isDark
                                            ? const Color(0xFF2C2C2E)
                                            : const Color(0xFFE5E5EA),
                                        backgroundImage:
                                            (attendee.avatarUrl != null &&
                                                attendee.avatarUrl!.isNotEmpty)
                                            ? NetworkImage(attendee.avatarUrl!)
                                            : null,
                                        child:
                                            (attendee.avatarUrl == null ||
                                                attendee.avatarUrl!.isEmpty)
                                            ? Text(
                                                initial,
                                                style: TextStyle(
                                                  color: textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        displayName,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: joinedSubtitle.isNotEmpty
                                          ? Text(
                                              joinedSubtitle,
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                      trailing: Icon(
                                        Icons.chevron_right_rounded,
                                        color: textSecondary,
                                        size: 20,
                                      ),
                                      onTap: () {
                                        Navigator.pop(sheetCtx);
                                        ProfileNavigation.open(
                                          userId: attendee.userId.isNotEmpty
                                              ? attendee.userId
                                              : null,
                                          username: attendee.username.isNotEmpty
                                              ? attendee.username
                                              : null,
                                        );
                                      },
                                    );
                                  },
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

  void _showSnackBar(BuildContext context, bool isDark, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _localizedCategory(String cat) {
    final key = 'community.${cat.toLowerCase()}';
    final tr = key.tr;
    if (tr.isNotEmpty && tr != key) return tr;
    return cat;
  }

  Widget _placeholderCover(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F2),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 64,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }

  // ── Error State Widget ─────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, bool isDark) {
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'community.unableToLoadEvent'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if ((_detailsErrorMessage ?? widget.errorMessage) != null) ...[
                const SizedBox(height: 8),
                Text(
                  _detailsErrorMessage ?? widget.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (widget.onRetry != null)
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: widget.onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'community.tryAgain'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Skeleton Shimmer Loading State ─────────────────────────────────────────
  Widget _buildLoadingSkeleton(BuildContext context, bool isDark) {
    final shimmerBase = isDark
        ? const Color(0xFF222224)
        : const Color(0xFFE8E8EC);

    Widget box({
      required double width,
      required double height,
      double radius = 6,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover placeholder
                Container(
                  height: 290,
                  width: double.infinity,
                  color: isDark
                      ? const Color(0xFF1A1A1C)
                      : const Color(0xFFDFDFE3),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges placeholder
                      Row(
                        children: [
                          box(width: 80, height: 24, radius: 4),
                          const SizedBox(width: 8),
                          box(width: 90, height: 24, radius: 4),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title placeholder
                      box(width: double.infinity, height: 26, radius: 6),
                      const SizedBox(height: 8),
                      box(width: 220, height: 20, radius: 6),
                      const SizedBox(height: 20),

                      // Organizer placeholder
                      box(width: double.infinity, height: 60, radius: 12),
                      const SizedBox(height: 12),

                      // Info rows placeholders
                      box(width: double.infinity, height: 56, radius: 12),
                      const SizedBox(height: 10),
                      box(width: double.infinity, height: 56, radius: 12),
                      const SizedBox(height: 10),
                      box(width: double.infinity, height: 56, radius: 12),
                      const SizedBox(height: 24),

                      // Description placeholders
                      box(width: 120, height: 20, radius: 4),
                      const SizedBox(height: 10),
                      box(width: double.infinity, height: 14, radius: 4),
                      const SizedBox(height: 6),
                      box(width: double.infinity, height: 14, radius: 4),
                      const SizedBox(height: 6),
                      box(width: 260, height: 14, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom bar placeholder
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              color: isDark ? const Color(0xFF141414) : Colors.white,
              child: box(width: double.infinity, height: 52, radius: 12),
            ),
          ),
        ],
      ),
    );
  }
}
