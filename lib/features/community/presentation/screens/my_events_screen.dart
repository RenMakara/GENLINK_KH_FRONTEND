import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/community_models.dart';
import '../controllers/community_controller.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';

/// Owner-scoped Event list backed by GET /community/events/mine.
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  late final CommunityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CommunityController>();
    unawaited(_controller.fetchMyEvents());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? Colors.white70
        : AppColors.lightTextSecondary;
    final surface = isDark ? const Color(0xFF18181A) : Colors.white;
    final border = isDark ? const Color(0xFF2A2A2D) : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        title: Text('community.myEvents'.tr),
        actions: [
          IconButton(
            tooltip: 'community.create'.tr,
            onPressed: () async {
              await Get.to(() => const CreateEventScreen());
              if (mounted) {
                unawaited(_controller.fetchMyEvents(isRefresh: true));
              }
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoadingMyEvents.value &&
            _controller.myEvents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.hasMyEventsError.value &&
            _controller.myEvents.isEmpty) {
          return _ErrorState(
            message: _controller.myEventsErrorMessage.value.isNotEmpty
                ? _controller.myEventsErrorMessage.value
                : 'community.unableToLoadMyEvents'.tr,
            onRetry: () => _controller.fetchMyEvents(),
          );
        }

        if (_controller.myEvents.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _controller.fetchMyEvents(isRefresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: Center(
                    child: Text(
                      'community.noMyEvents'.tr,
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.fetchMyEvents(isRefresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 300) {
                unawaited(_controller.loadMoreMyEvents());
              }
              return false;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount:
                  _controller.myEvents.length +
                  (_controller.hasMoreMyEvents.value ? 1 : 0),
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == _controller.myEvents.length) {
                  return Center(
                    child: _controller.isLoadingMoreMyEvents.value
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const SizedBox(height: 12),
                  );
                }

                final event = _controller.myEvents[index];
                return _MyEventCard(
                  event: event,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onTap: () => Get.to(() => EventDetailsScreen(event: event)),
                  onEdit: () async {
                    await Get.to(() => CreateEventScreen(eventToEdit: event));
                    if (mounted) {
                      unawaited(_controller.fetchMyEvents(isRefresh: true));
                    }
                  },
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _MyEventCard extends StatelessWidget {
  const _MyEventCard({
    required this.event,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    required this.onEdit,
  });

  final EventModel event;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  String get _statusKey {
    switch (event.normalizedStatus) {
      case 'DRAFT':
        return 'community.eventDraft';
      case 'PUBLISHED':
        return 'community.published';
      case 'CANCELLED':
        return 'community.eventCancelled';
      case 'COMPLETED':
        return 'community.eventCompleted';
      default:
        return event.normalizedStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white54 : AppColors.lightTextMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event_outlined, color: textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.formattedDateRange.isNotEmpty
                          ? event.formattedDateRange
                          : 'community.dateTbc'.tr,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusKey.tr,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'community.editEvent'.tr,
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('community.tryAgain'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
