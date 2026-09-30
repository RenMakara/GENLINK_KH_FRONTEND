import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import '../../../../shared/utils/current_user.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import 'story_controller.dart';

class CommunityController extends GetxController {
  late CommunityRepository repository;
  final CommunityRepository? _injectedRepository;

  CommunityController({CommunityRepository? repository})
    : _injectedRepository = repository {
    if (repository != null) {
      this.repository = repository;
    }
  }

  final ScrollController scrollController = ScrollController();

  String? get currentUserId {
    final id = CurrentUser.id;
    if (id.isNotEmpty) return id;
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().currentUser.value?.id;
    }
    return null;
  }

  String get currentUserName {
    if (Get.isRegistered<AuthController>()) {
      final user = Get.find<AuthController>().currentUser.value;
      if (user != null) {
        if (user.fullName.isNotEmpty) return user.fullName;
        if (user.username.isNotEmpty) return user.username;
      }
    }
    return '';
  }

  final selectedCategory = 'Feed'.obs;
  final selectedForumCategory = 'All'.obs;
  final categories = ['Feed', 'Forum', 'Event', 'Career'];

  final isLoadingFeed = false.obs;
  final isRefreshingFeed = false.obs;
  final isLoadingMore = false.obs;
  final hasMorePosts = true.obs;
  final hasMorePostsError = false.obs;
  final morePostsErrorMessage = ''.obs;
  final currentPage = 1.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  int _feedRequestGeneration = 0;
  Future<void>? _feedLoadFuture;

  final isUploadingPost = false.obs;
  final uploadProgress = 0.0.obs;

  final posts = <CommunityPostModel>[].obs;

  /// Reposts are loaded separately so they never become part of the main feed.
  final repostedPosts = <CommunityPostModel>[].obs;
  final isLoadingRepostedPosts = false.obs;
  bool _hasLoadedRepostedPosts = false;

  /// Discussion reposts are profile-only and never join the Forum list.
  final discussionRepostsByUser = <String, List<ForumTopicModel>>{}.obs;
  final isLoadingDiscussionReposts = <String, bool>{}.obs;
  final Set<String> _loadedDiscussionRepostUsers = <String>{};
  final Set<String> _inFlightDiscussionRepostUsers = <String>{};
  final activeComments = <CommentModel>[].obs;
  final isLoadingComments = false.obs;
  final commentsErrorMessage = ''.obs;
  String? _activeCommentsPostId;
  final followLoadingUserIds = <String>{}.obs;

  final stories = <StoryModel>[
    StoryModel(
      id: '1',
      name: 'Your Story',
      avatarText: 'S',
      isUser: true,
      hasActiveStory: false,
    ),
    StoryModel(id: '2', name: 'Dary', avatarText: 'D', hasActiveStory: true),
    StoryModel(
      id: '3',
      name: 'AIS Tech Club',
      avatarText: 'AIS',
      hasActiveStory: true,
    ),
    StoryModel(id: '4', name: 'MayMay', avatarText: 'M', hasActiveStory: true),
  ].obs;

  final recommendedGroups = <RecommendedGroupModel>[
    RecommendedGroupModel(
      id: 'g1',
      name: 'IT Club Cambodia',
      memberCount: '1.2k Members',
      iconText: 'IT',
    ),
    RecommendedGroupModel(
      id: 'g2',
      name: 'UI/UX Design KH',
      memberCount: '850 Members',
      iconText: 'UX',
    ),
  ].obs;

  final suggestedUsers = <SuggestedUserModel>[
    SuggestedUserModel(
      id: 'u1',
      name: 'Rathana P.',
      role: 'Mobile Dev at CADT',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    SuggestedUserModel(
      id: 'u2',
      name: 'Sothea N.',
      role: 'Product Designer',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    ),
  ].obs;

  final events = <EventModel>[].obs;
  final isLoadingEvents = false.obs;
  final isRefreshingEvents = false.obs;
  final hasEventsError = false.obs;
  final eventsErrorMessage = ''.obs;
  final isLoadingMoreEvents = false.obs;
  final hasMoreEvents = true.obs;
  final currentEventsPage = 1.obs;

  final myEvents = <EventModel>[].obs;
  final isLoadingMyEvents = false.obs;
  final isRefreshingMyEvents = false.obs;
  final hasMyEventsError = false.obs;
  final myEventsErrorMessage = ''.obs;
  final isLoadingMoreMyEvents = false.obs;
  final hasMoreMyEvents = true.obs;
  final currentMyEventsPage = 1.obs;

  final eventBookmarkLoadingIds = <String>{}.obs;
  final Set<String> _eventHydrationRequests = <String>{};

  // ── Opportunities (Career) ──────────────────────────────────────────
  final opportunities = <OpportunityModel>[].obs;
  final isLoadingOpportunities = false.obs;
  final isRefreshingOpportunities = false.obs;
  final hasOpportunitiesError = false.obs;
  final opportunitiesErrorMessage = ''.obs;
  final isLoadingMoreOpportunities = false.obs;
  final hasMoreOpportunities = true.obs;
  final hasMoreOpportunitiesError = false.obs;
  final opportunitiesMoreErrorMessage = ''.obs;
  final currentOpportunitiesPage = 1.obs;
  int _opportunitiesRequestGeneration = 0;
  final selectedOpportunityType = 'All'.obs;
  final opportunityBookmarkLoadingIds = <String>{}.obs;
  static const opportunityCategories = [
    'All',
    'Internship',
    'Scholarship',
    'Job',
    'Hackathon',
    'Volunteer',
  ];

  void _upsertEvent(RxList<EventModel> collection, EventModel event) {
    final index = collection.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      collection.insert(0, event);
    } else {
      collection[index] = event;
    }
    collection.refresh();
  }

  final isCreatingEvent = false.obs;

  Future<EventModel> createEvent(
    EventCreateRequest request, {
    File? coverImageFile,
  }) async {
    isCreatingEvent.value = true;
    try {
      String? uploadedCoverUrl = request.coverImageUrl;

      if (coverImageFile != null &&
          (uploadedCoverUrl == null || uploadedCoverUrl.isEmpty) &&
          Get.isRegistered<MediaUploadService>()) {
        final uploadService = Get.find<MediaUploadService>();
        final path = coverImageFile.path.toLowerCase();
        final contentType = path.endsWith('.png')
            ? 'image/png'
            : path.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
        uploadService.validateFile(
          sizeBytes: await coverImageFile.length(),
          contentType: contentType,
          purpose: MediaPurpose.eventCover,
        );
        final bytes = await coverImageFile.readAsBytes();
        final media = await uploadService.upload(
          bytes: bytes,
          contentType: contentType,
          purpose: MediaPurpose.eventCover,
        );
        uploadedCoverUrl = media.url;
      }

      final finalRequest = EventCreateRequest(
        title: request.title,
        description: request.description,
        category: request.category,
        coverImageUrl: uploadedCoverUrl,
        startDateTime: request.startDateTime,
        endDateTime: request.endDateTime,
        mode: request.mode,
        meetingUrl: request.meetingUrl,
        locationName: request.locationName,
        latitude: request.latitude,
        longitude: request.longitude,
        attendeeLimit: request.attendeeLimit,
        status: request.status,
        language: request.language,
        paid: request.paid,
        price: request.price,
        currency: request.currency,
      );

      var createdEvent = await repository.createEvent(finalRequest);

      final currentUid = CurrentUser.id.isNotEmpty
          ? CurrentUser.id
          : (Get.isRegistered<AuthController>()
                ? Get.find<AuthController>().currentUser.value?.id ?? ''
                : '');
      final currentName = CurrentUser.name;
      final currentUsername = CurrentUser.username;
      final currentAvatar = CurrentUser.avatarUrl;

      if (createdEvent.organizerId == null ||
          createdEvent.organizerId!.isEmpty) {
        if (currentUid.isNotEmpty) {
          createdEvent = createdEvent.copyWith(
            organizerId: currentUid,
            organizerName: createdEvent.organizerName.isNotEmpty
                ? createdEvent.organizerName
                : (currentName.isNotEmpty && currentName != 'Guest'
                      ? currentName
                      : ''),
            organizerUsername:
                createdEvent.organizerUsername?.isNotEmpty == true
                ? createdEvent.organizerUsername
                : (currentUsername.isNotEmpty ? currentUsername : null),
            organizerAvatar: createdEvent.organizerAvatar ?? currentAvatar,
          );
        }
      }

      final eventToStore =
          coverImageFile != null && createdEvent.coverImageFile == null
          ? createdEvent.copyWith(coverImageFile: coverImageFile)
          : createdEvent;
      if (eventToStore.isPublished) {
        _upsertEvent(events, eventToStore);
      }
      _upsertEvent(myEvents, eventToStore);

      // Refresh events from backend to ensure synchronization
      try {
        await refreshEvents();
        if (coverImageFile != null && eventToStore.isPublished) {
          final idx = events.indexWhere((e) => e.id == eventToStore.id);
          if (idx != -1 && events[idx].coverImageFile == null) {
            events[idx] = events[idx].copyWith(coverImageFile: coverImageFile);
            events.refresh();
          }
        }
      } catch (_) {
        // If refresh fails, eventToStore is already present in events
      }

      if (eventToStore.isPublished) {
        final currentUid = CurrentUser.id;
        final currentName = CurrentUser.name;
        final currentAvatar = CurrentUser.avatarUrl;
        final currentUsername = CurrentUser.username;
        final eventPost = CommunityPostModel(
          id: 'post_event_${eventToStore.id}',
          userId: currentUid.isNotEmpty
              ? currentUid
              : (eventToStore.organizerId ?? 'user_1'),
          authorName: eventToStore.organizerName.isNotEmpty
              ? eventToStore.organizerName
              : (currentName.isNotEmpty && currentName != 'Guest'
                    ? currentName
                    : 'Organizer'),
          authorTag: currentUsername.isNotEmpty
              ? '@$currentUsername'
              : '@organizer',
          authorAvatar: eventToStore.organizerAvatar?.isNotEmpty == true
              ? eventToStore.organizerAvatar!
              : (currentAvatar?.isNotEmpty == true ? currentAvatar! : ''),
          timeAgo: 'Just now',
          content: eventToStore.description.isNotEmpty
              ? eventToStore.description
              : eventToStore.title,
          postType: 'event',
          attachedEvent: eventToStore,
          isOwner: true,
        );
        final existingPostIdx = posts.indexWhere(
          (post) =>
              post.attachedEvent?.id == eventToStore.id ||
              post.id == eventPost.id,
        );
        if (existingPostIdx == -1) {
          posts.insert(0, eventPost);
          posts.refresh();
        }
      }

      return eventToStore;
    } finally {
      isCreatingEvent.value = false;
    }
  }

  void addEventLocally(EventModel event) {
    final currentUid = CurrentUser.id.isNotEmpty
        ? CurrentUser.id
        : (Get.isRegistered<AuthController>()
              ? Get.find<AuthController>().currentUser.value?.id ?? ''
              : '');
    final currentName = CurrentUser.name;
    final currentUsername = CurrentUser.username;
    final currentAvatar = CurrentUser.avatarUrl;

    var eventToStore = event.copyWith();
    if (eventToStore.organizerId == null || eventToStore.organizerId!.isEmpty) {
      if (currentUid.isNotEmpty) {
        eventToStore = eventToStore.copyWith(
          organizerId: currentUid,
          organizerName: eventToStore.organizerName.isNotEmpty
              ? eventToStore.organizerName
              : (currentName.isNotEmpty && currentName != 'Guest'
                    ? currentName
                    : ''),
          organizerUsername: eventToStore.organizerUsername?.isNotEmpty == true
              ? eventToStore.organizerUsername
              : (currentUsername.isNotEmpty ? currentUsername : null),
          organizerAvatar: eventToStore.organizerAvatar ?? currentAvatar,
        );
      }
    }
    final existingEventIndex = events.indexWhere((item) => item.id == event.id);
    if (existingEventIndex == -1) {
      events.insert(0, eventToStore);
    } else {
      events[existingEventIndex] = eventToStore;
    }
    events.refresh();

    final existingPostIndex = posts.indexWhere(
      (post) =>
          post.attachedEvent?.id == eventToStore.id ||
          post.eventId == eventToStore.id,
    );
    if (existingPostIndex == -1) {
      final currentName = CurrentUser.name;
      final currentUsername = CurrentUser.username;
      final currentAvatar = CurrentUser.avatarUrl;
      posts.insert(
        0,
        CommunityPostModel(
          id: 'post_event_${eventToStore.id}',
          userId: eventToStore.organizerId ?? CurrentUser.id,
          authorName: eventToStore.organizerName.isNotEmpty
              ? eventToStore.organizerName
              : (currentName.isNotEmpty ? currentName : 'Organizer'),
          authorTag: currentUsername.isNotEmpty
              ? '@$currentUsername'
              : '@organizer',
          authorAvatar: eventToStore.organizerAvatar?.isNotEmpty == true
              ? eventToStore.organizerAvatar!
              : (currentAvatar ?? ''),
          timeAgo: 'Just now',
          content: eventToStore.description.isNotEmpty
              ? eventToStore.description
              : eventToStore.title,
          postType: 'event',
          eventId: eventToStore.id,
          attachedEvent: eventToStore,
          isOwner: true,
        ),
      );
      posts.refresh();
    }
  }

  void toggleRsvp(String eventId) {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final ev = events[idx];
    final nextIsRsvped = !ev.isRsvped;
    final nextAttendeesCount = ev.attendeesCount + (nextIsRsvped ? 1 : -1);
    syncEventRsvp(
      eventId,
      isRsvped: nextIsRsvped,
      attendeesCount: nextAttendeesCount < 0 ? 0 : nextAttendeesCount,
      status: nextIsRsvped ? 'JOINED' : 'CANCELLED',
    );
  }

  final isRegisteringEvent = false.obs;
  final isCancellingEventRsvp = false.obs;

  void syncEventRsvp(
    String eventId, {
    required bool isRsvped,
    int? attendeesCount,
    String? status,
  }) {
    final idx = events.indexWhere((event) => event.id == eventId);
    if (idx != -1) {
      final event = events[idx];
      final wasRsvped = event.isRsvped;
      event.isRsvped = isRsvped;
      if (attendeesCount != null && attendeesCount >= 0) {
        event.attendeesCount = attendeesCount;
      } else if (isRsvped && !wasRsvped) {
        event.attendeesCount += 1;
      } else if (!isRsvped && wasRsvped && event.attendeesCount > 0) {
        event.attendeesCount -= 1;
      }
      event.myRsvpStatus = status ?? (isRsvped ? 'JOINED' : 'CANCELLED');
      events.refresh();
    }

    var changedInPosts = false;
    for (var i = 0; i < posts.length; i++) {
      final attachedEvent = posts[i].attachedEvent;
      if (attachedEvent?.id != eventId) continue;
      final wasRsvped = attachedEvent!.isRsvped;
      final count =
          attendeesCount ??
          (isRsvped && !wasRsvped
              ? attachedEvent.attendeesCount + 1
              : (!isRsvped && wasRsvped && attachedEvent.attendeesCount > 0
                    ? attachedEvent.attendeesCount - 1
                    : attachedEvent.attendeesCount));
      posts[i] = posts[i].copyWith(
        attachedEvent: attachedEvent.copyWith(
          isRsvped: isRsvped,
          attendeesCount: count,
          myRsvpStatus: status ?? (isRsvped ? 'JOINED' : 'CANCELLED'),
        ),
      );
      changedInPosts = true;
    }
    if (changedInPosts) posts.refresh();
  }

  Future<RsvpResponseModel> registerForEvent(
    String eventId,
    EventRegistrationRequest request,
  ) async {
    if (isRegisteringEvent.value) {
      throw const AppError(
        message: 'Registration is already in progress.',
        errorCode: 'REGISTRATION_IN_PROGRESS',
      );
    }
    isRegisteringEvent.value = true;
    try {
      final response = await repository.rsvpEvent(eventId, request: request);
      syncEventRsvp(
        eventId,
        isRsvped: true,
        attendeesCount: response.attendeeCount,
        status: response.status,
      );
      return response;
    } finally {
      isRegisteringEvent.value = false;
    }
  }

  Future<bool> cancelEventRegistration(String eventId) async {
    if (isCancellingEventRsvp.value) return false;
    isCancellingEventRsvp.value = true;
    try {
      final success = await repository.cancelRsvpEvent(eventId);
      if (success) {
        syncEventRsvp(eventId, isRsvped: false, status: 'CANCELLED');
      }
      return success;
    } finally {
      isCancellingEventRsvp.value = false;
    }
  }

  final isDeletingEvent = false.obs;
  final isUpdatingEvent = false.obs;

  Future<bool> deleteEvent(String eventId) async {
    if (isDeletingEvent.value) return false;
    isDeletingEvent.value = true;
    try {
      final success = await repository.deleteEvent(eventId);
      if (success) {
        events.removeWhere((e) => e.id == eventId);
        myEvents.removeWhere((e) => e.id == eventId);
        posts.removeWhere(
          (p) => p.eventId == eventId || p.attachedEvent?.id == eventId,
        );
        events.refresh();
        myEvents.refresh();
        posts.refresh();
      }
      return success;
    } finally {
      isDeletingEvent.value = false;
    }
  }

  Future<EventModel> updateEvent(
    String eventId,
    EventCreateRequest request, {
    File? coverImageFile,
  }) async {
    isUpdatingEvent.value = true;
    try {
      final updatedEvent = await repository.updateEvent(eventId, request);

      final eventToStore =
          coverImageFile != null && updatedEvent.coverImageFile == null
          ? updatedEvent.copyWith(coverImageFile: coverImageFile)
          : updatedEvent;

      if (eventToStore.isPublished) {
        _upsertEvent(events, eventToStore);
      } else {
        events.removeWhere((event) => event.id == eventId);
        events.refresh();
      }
      _upsertEvent(myEvents, eventToStore);

      for (int i = 0; i < posts.length; i++) {
        if (posts[i].eventId == eventId ||
            posts[i].attachedEvent?.id == eventId) {
          posts[i] = posts[i].copyWith(
            attachedEvent: eventToStore,
            content: eventToStore.description.isNotEmpty
                ? eventToStore.description
                : eventToStore.title,
          );
        }
      }
      posts.refresh();

      return eventToStore;
    } finally {
      isUpdatingEvent.value = false;
    }
  }

  Future<EventPageModel<EventAttendeeModel>> fetchEventAttendeesPage(
    String eventId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await repository.getEventAttendeesPage(
        eventId,
        page: page,
        limit: limit,
      );
    } on UnimplementedError {
      return EventPageModel<EventAttendeeModel>.fromContent(
        await repository.getEventAttendees(eventId, page: page, limit: limit),
        page: page - 1,
        size: limit,
      );
    } on NoSuchMethodError {
      return EventPageModel<EventAttendeeModel>.fromContent(
        await repository.getEventAttendees(eventId, page: page, limit: limit),
        page: page - 1,
        size: limit,
      );
    }
  }

  Future<List<EventAttendeeModel>> fetchEventAttendees(
    String eventId, {
    int page = 1,
    int limit = 20,
  }) async {
    final result = await fetchEventAttendeesPage(
      eventId,
      page: page,
      limit: limit,
    );
    return result.content;
  }

  Future<bool> toggleEventBookmark(String eventId) async {
    if (eventBookmarkLoadingIds.contains(eventId)) return false;
    final eventIndex = events.indexWhere((e) => e.id == eventId);
    final myEventIndex = myEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1 && myEventIndex == -1) return false;
    final ev = eventIndex != -1 ? events[eventIndex] : myEvents[myEventIndex];
    final wasBookmarked = ev.isBookmarked;
    final nextBookmarked = !wasBookmarked;
    eventBookmarkLoadingIds.add(eventId);

    void setBookmark(bool value) {
      if (eventIndex != -1) events[eventIndex].isBookmarked = value;
      if (myEventIndex != -1) myEvents[myEventIndex].isBookmarked = value;
      if (eventIndex != -1) events.refresh();
      if (myEventIndex != -1) myEvents.refresh();
    }

    setBookmark(nextBookmarked);

    for (int i = 0; i < posts.length; i++) {
      if (posts[i].attachedEvent?.id == eventId) {
        posts[i] = posts[i].copyWith(
          attachedEvent: posts[i].attachedEvent!.copyWith(
            isBookmarked: nextBookmarked,
          ),
        );
      }
    }
    posts.refresh();

    try {
      final success = await repository.toggleEventBookmark(
        eventId,
        isCurrentlyBookmarked: wasBookmarked,
      );
      return success;
    } catch (e) {
      setBookmark(wasBookmarked);
      for (int i = 0; i < posts.length; i++) {
        if (posts[i].attachedEvent?.id == eventId) {
          posts[i] = posts[i].copyWith(
            attachedEvent: posts[i].attachedEvent!.copyWith(
              isBookmarked: wasBookmarked,
            ),
          );
        }
      }
      posts.refresh();
      return false;
    } finally {
      eventBookmarkLoadingIds.remove(eventId);
    }
  }

  Future<EventModel> fetchEventDetails(String eventId) async {
    var event = await repository.getEventDetails(eventId);
    final savedIds = await repository.getSavedEventIds();
    event = event.copyWith(isBookmarked: savedIds.contains(event.id));
    if (event.isPublished) {
      _upsertEvent(events, event);
    } else {
      events.removeWhere((item) => item.id == event.id);
      events.refresh();
    }
    _upsertEvent(myEvents, event);
    return event;
  }

  Future<void> fetchEvents({bool isRefresh = false}) async {
    if (isLoadingEvents.value || isRefreshingEvents.value) return;
    if (isRefresh) {
      isRefreshingEvents.value = true;
    } else {
      isLoadingEvents.value = true;
    }
    hasEventsError.value = false;
    eventsErrorMessage.value = '';

    try {
      final fetchedPage = await _getEventsPage(page: 1, limit: 20);
      final fetched = fetchedPage.content;
      final savedIds = await repository.getSavedEventIds();
      for (final event in fetched) {
        event.isBookmarked = savedIds.contains(event.id);
      }
      events.assignAll(fetched);
      currentEventsPage.value = 1;
      hasMoreEvents.value = fetchedPage.hasNext;
      hasEventsError.value = false;
      eventsErrorMessage.value = '';
    } catch (e) {
      hasEventsError.value = true;
      eventsErrorMessage.value = e is AppError
          ? e.message
          : 'Unable to load events';
    } finally {
      if (isRefresh) {
        isRefreshingEvents.value = false;
      } else {
        isLoadingEvents.value = false;
      }
      events.refresh();
    }
  }

  Future<void> loadMoreEvents() async {
    if (isLoadingMoreEvents.value ||
        !hasMoreEvents.value ||
        isLoadingEvents.value ||
        isRefreshingEvents.value) {
      return;
    }

    isLoadingMoreEvents.value = true;
    try {
      final nextPage = currentEventsPage.value + 1;
      final fetchedPage = await _getEventsPage(page: nextPage, limit: 20);
      final savedIds = await repository.getSavedEventIds();
      for (final event in fetchedPage.content) {
        event.isBookmarked = savedIds.contains(event.id);
        final existing = events.indexWhere((item) => item.id == event.id);
        if (existing == -1) {
          events.add(event);
        } else {
          events[existing] = event;
        }
      }
      currentEventsPage.value = nextPage;
      hasMoreEvents.value = fetchedPage.hasNext;
      events.refresh();
    } catch (_) {
      // Keep the already loaded list visible; a later scroll can retry.
    } finally {
      isLoadingMoreEvents.value = false;
    }
  }

  Future<void> fetchMyEvents({bool isRefresh = false}) async {
    if (isLoadingMyEvents.value || isRefreshingMyEvents.value) return;
    if (isRefresh) {
      isRefreshingMyEvents.value = true;
    } else {
      isLoadingMyEvents.value = true;
    }
    hasMyEventsError.value = false;
    myEventsErrorMessage.value = '';

    try {
      final fetchedPage = await _getMyEventsPage(page: 1, limit: 20);
      final savedIds = await repository.getSavedEventIds();
      for (final event in fetchedPage.content) {
        event.isBookmarked = savedIds.contains(event.id);
      }
      myEvents.assignAll(fetchedPage.content);
      currentMyEventsPage.value = 1;
      hasMoreMyEvents.value = fetchedPage.hasNext;
    } catch (e) {
      myEvents.clear();
      hasMyEventsError.value = true;
      myEventsErrorMessage.value = e is AppError
          ? e.message
          : 'Unable to load your events';
    } finally {
      isLoadingMyEvents.value = false;
      isRefreshingMyEvents.value = false;
      myEvents.refresh();
    }
  }

  Future<void> loadMoreMyEvents() async {
    if (isLoadingMoreMyEvents.value ||
        !hasMoreMyEvents.value ||
        isLoadingMyEvents.value ||
        isRefreshingMyEvents.value) {
      return;
    }

    isLoadingMoreMyEvents.value = true;
    try {
      final nextPage = currentMyEventsPage.value + 1;
      final fetchedPage = await _getMyEventsPage(page: nextPage, limit: 20);
      for (final event in fetchedPage.content) {
        final existing = myEvents.indexWhere((item) => item.id == event.id);
        if (existing == -1) {
          myEvents.add(event);
        } else {
          myEvents[existing] = event;
        }
      }
      currentMyEventsPage.value = nextPage;
      hasMoreMyEvents.value = fetchedPage.hasNext;
      myEvents.refresh();
    } catch (_) {
      // Keep already loaded owner events visible.
    } finally {
      isLoadingMoreMyEvents.value = false;
    }
  }

  Future<EventPageModel<EventModel>> _getEventsPage({
    required int page,
    required int limit,
  }) async {
    try {
      return await repository.getEventsPage(page: page, limit: limit);
    } on UnimplementedError {
      return _legacyEventPage(
        await repository.getEvents(page: page, limit: limit),
        page: page,
        limit: limit,
      );
    } on NoSuchMethodError {
      return _legacyEventPage(
        await repository.getEvents(page: page, limit: limit),
        page: page,
        limit: limit,
      );
    }
  }

  Future<EventPageModel<EventModel>> _getMyEventsPage({
    required int page,
    required int limit,
  }) async {
    try {
      return await repository.getMyEventsPage(page: page, limit: limit);
    } on UnimplementedError {
      return _legacyEventPage(
        await repository.getMyEvents(page: page, limit: limit),
        page: page,
        limit: limit,
      );
    } on NoSuchMethodError {
      return _legacyEventPage(
        await repository.getMyEvents(page: page, limit: limit),
        page: page,
        limit: limit,
      );
    }
  }

  EventPageModel<EventModel> _legacyEventPage(
    List<EventModel> content, {
    required int page,
    required int limit,
  }) {
    return EventPageModel<EventModel>.fromContent(
      content,
      page: page - 1,
      size: limit,
    );
  }

  Future<void> refreshEvents() async {
    await fetchEvents(isRefresh: true);
  }

  // ── Opportunities (Career) ──────────────────────────────────────────

  Future<void> fetchOpportunities({bool isRefresh = false}) async {
    if (!isRefresh &&
        (isLoadingOpportunities.value || isRefreshingOpportunities.value)) {
      return;
    }
    final requestGeneration = ++_opportunitiesRequestGeneration;
    if (isRefresh) {
      isRefreshingOpportunities.value = true;
    } else {
      isLoadingOpportunities.value = true;
    }
    hasOpportunitiesError.value = false;
    opportunitiesErrorMessage.value = '';

    try {
      final type = selectedOpportunityType.value == 'All'
          ? null
          : selectedOpportunityType.value;
      final fetched = await repository.getOpportunitiesPage(
        type: type,
        includeExpired: false,
        page: 1,
        limit: 20,
      );
      if (requestGeneration != _opportunitiesRequestGeneration) return;
      opportunities.assignAll(fetched.content);
      currentOpportunitiesPage.value = 1;
      hasMoreOpportunities.value = fetched.hasNext;
      hasMoreOpportunitiesError.value = false;
      opportunitiesMoreErrorMessage.value = '';
    } catch (e) {
      if (requestGeneration != _opportunitiesRequestGeneration) return;
      if (e is! NoSuchMethodError) {
        debugPrint('[CommunityController] fetchOpportunities error: $e');
      }
      hasOpportunitiesError.value = true;
      opportunitiesErrorMessage.value = e is AppError
          ? e.message
          : 'Unable to load opportunities';
    } finally {
      if (requestGeneration == _opportunitiesRequestGeneration) {
        isLoadingOpportunities.value = false;
        isRefreshingOpportunities.value = false;
      }
      opportunities.refresh();
    }
  }

  Future<void> loadMoreOpportunities() async {
    if (isLoadingMoreOpportunities.value ||
        isLoadingOpportunities.value ||
        isRefreshingOpportunities.value ||
        !hasMoreOpportunities.value) {
      return;
    }
    isLoadingMoreOpportunities.value = true;
    final generation = _opportunitiesRequestGeneration;
    final nextPage = currentOpportunitiesPage.value + 1;
    try {
      final type = selectedOpportunityType.value == 'All'
          ? null
          : selectedOpportunityType.value;
      final fetched = await repository.getOpportunitiesPage(
        type: type,
        includeExpired: false,
        page: nextPage,
        limit: 20,
      );
      if (generation != _opportunitiesRequestGeneration) return;
      final seen = opportunities.map((item) => item.id).toSet();
      for (final item in fetched.content) {
        if (seen.add(item.id)) opportunities.add(item);
      }
      currentOpportunitiesPage.value = nextPage;
      hasMoreOpportunities.value = fetched.hasNext;
      hasMoreOpportunitiesError.value = false;
      opportunitiesMoreErrorMessage.value = '';
    } catch (e) {
      if (generation == _opportunitiesRequestGeneration) {
        hasMoreOpportunitiesError.value = true;
        opportunitiesMoreErrorMessage.value = e is AppError
            ? e.message
            : 'Unable to load more opportunities';
      }
    } finally {
      isLoadingMoreOpportunities.value = false;
    }
  }

  Future<void> refreshOpportunities() async {
    await fetchOpportunities(isRefresh: true);
  }

  void filterOpportunitiesByType(String type) {
    if (selectedOpportunityType.value == type) return;
    selectedOpportunityType.value = type;
    fetchOpportunities(isRefresh: true);
  }

  Future<bool> toggleOpportunityBookmark(String opportunityId) async {
    if (opportunityBookmarkLoadingIds.contains(opportunityId)) return false;
    opportunityBookmarkLoadingIds.add(opportunityId);

    try {
      final index = opportunities.indexWhere((o) => o.id == opportunityId);
      final currentSaved = index != -1 ? opportunities[index].savedByMe : false;
      final newSaved = await repository.toggleSaveOpportunity(
        opportunityId,
        currentSaved,
      );

      if (index != -1) {
        opportunities[index] = opportunities[index].copyWith(
          savedByMe: newSaved,
        );
        opportunities.refresh();
      }
      return newSaved;
    } catch (e) {
      debugPrint('[CommunityController] toggleOpportunityBookmark error: $e');
      return false;
    } finally {
      opportunityBookmarkLoadingIds.remove(opportunityId);
    }
  }

  final selectedEventDate = 'All'.obs;
  final selectedEventCategories = <String>{}.obs;
  final selectedEventMode = 'All'.obs;
  final selectedEventPrice = 'All'.obs;

  bool get isEventFilterActive =>
      (selectedEventDate.value != 'All' &&
          selectedEventDate.value.isNotEmpty) ||
      selectedEventCategories.isNotEmpty ||
      selectedEventMode.value != 'All' ||
      selectedEventPrice.value != 'All';

  List<EventModel> get filteredEvents {
    final now = DateTime.now();
    return events.where((e) {
      if (selectedEventCategories.isNotEmpty) {
        final catLower = e.category.toLowerCase();
        final matchesCategory = selectedEventCategories.any((cat) {
          final filterCatLower = cat.toLowerCase();
          return catLower.contains(filterCatLower) ||
              filterCatLower.contains(catLower);
        });
        if (!matchesCategory) {
          return false;
        }
      }
      if (selectedEventMode.value != 'All') {
        final isOnline = e.eventType.toLowerCase().contains('online');
        final filterModeLower = selectedEventMode.value.toLowerCase();
        if (filterModeLower.contains('online') && !isOnline) {
          return false;
        }
        if ((filterModeLower.contains('in person') ||
                filterModeLower.contains('campus')) &&
            isOnline) {
          return false;
        }
      }
      if (selectedEventPrice.value == 'Free' && e.isPaid) {
        return false;
      }
      if (selectedEventPrice.value == 'Paid' && !e.isPaid) {
        return false;
      }
      if (selectedEventDate.value != 'All' &&
          selectedEventDate.value.isNotEmpty) {
        if (!matchesEventDateFilter(
          e.startDateTime,
          selectedEventDate.value,
          now: now,
        )) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @visibleForTesting
  static bool matchesEventDateFilter(
    DateTime? eventStart,
    String filter, {
    required DateTime now,
  }) {
    if (filter == 'All' || filter.isEmpty) return true;
    if (eventStart == null) return false;

    final localNow = now.toLocal();
    final localStart = eventStart.toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final nextDay = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final nextWeek = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(localNow.year, localNow.month);
    final nextMonth = DateTime(localNow.year, localNow.month + 1);

    return switch (filter) {
      'Today' => !localStart.isBefore(today) && localStart.isBefore(nextDay),
      'This Week' =>
        !localStart.isBefore(weekStart) && localStart.isBefore(nextWeek),
      'This Month' =>
        !localStart.isBefore(monthStart) && localStart.isBefore(nextMonth),
      'Upcoming' => localStart.isAfter(localNow),
      _ => true,
    };
  }

  void resetEventFilter() {
    selectedEventDate.value = 'All';
    selectedEventCategories.clear();
    selectedEventMode.value = 'All';
    selectedEventPrice.value = 'All';
    events.refresh();
  }

  void applyEventFilter({
    String date = 'All',
    Set<String> categories = const {},
    String mode = 'All',
    String price = 'All',
  }) {
    selectedEventDate.value = date;
    selectedEventCategories.assignAll(categories);
    selectedEventMode.value = mode;
    selectedEventPrice.value = price;
    events.refresh();
  }

  final forumPinnedDiscussions = <ForumTopicModel>[].obs;

  final forumLatestDiscussions = <ForumTopicModel>[].obs;

  final isLoadingForumDiscussions = false.obs;
  RxBool get isLoadingDiscussions => isLoadingForumDiscussions;

  final isRefreshingForumDiscussions = false.obs;
  final hasForumError = false.obs;
  final forumErrorMessage = ''.obs;
  final isLoadingMoreForumDiscussions = false.obs;
  final hasMoreForumDiscussions = true.obs;
  final hasMoreForumDiscussionsError = false.obs;
  final forumMoreErrorMessage = ''.obs;
  final currentForumDiscussionsPage = 1.obs;
  int _discussionRequestGeneration = 0;
  RxString get discussionsError => forumErrorMessage;

  final isPublishingDiscussion = false.obs;
  final inFlightDiscussionLikes = <String>{}.obs;
  final inFlightCommentLikes = <String>{}.obs;
  final inFlightDiscussionReposts = <String>{}.obs;

  final discussionLikers = <String, List<ForumLikerModel>>{}.obs;
  final isLoadingDiscussionLikers = <String, bool>{}.obs;

  final postLikers = <String, List<PostLikerModel>>{}.obs;
  final isLoadingPostLikers = <String, bool>{}.obs;

  Future<List<PostLikerModel>> fetchPostLikers(
    String postId, {
    int page = 0,
    int size = 20,
  }) async {
    if (postId.trim().isEmpty) {
      return [];
    }
    isLoadingPostLikers[postId] = true;
    try {
      final likers = await repository.getPostLikers(
        postId,
        page: page,
        size: size,
      );

      final currentList = page == 0
          ? <PostLikerModel>[]
          : (postLikers[postId] ?? <PostLikerModel>[]);
      final mergedLikers = List<PostLikerModel>.from(currentList);
      for (final liker in likers) {
        if (!mergedLikers.any((l) => l.id == liker.id)) {
          mergedLikers.add(liker);
        }
      }

      postLikers[postId] = mergedLikers;
      postLikers.refresh();
      return mergedLikers;
    } finally {
      isLoadingPostLikers[postId] = false;
    }
  }

  Future<List<ForumLikerModel>> fetchDiscussionLikers(
    String discussionId, {
    int page = 0,
    int size = 20,
  }) async {
    if (discussionId.trim().isEmpty) {
      return [];
    }
    isLoadingDiscussionLikers[discussionId] = true;
    try {
      final likers = await repository.getDiscussionLikers(
        discussionId,
        page: page,
        size: size,
      );

      final currentList = page == 0
          ? <ForumLikerModel>[]
          : (discussionLikers[discussionId] ?? <ForumLikerModel>[]);
      final mergedLikers = List<ForumLikerModel>.from(currentList);
      for (final liker in likers) {
        if (!mergedLikers.any((l) => l.id == liker.id)) {
          mergedLikers.add(liker);
        }
      }

      discussionLikers[discussionId] = mergedLikers;
      discussionLikers.refresh();

      final latestIdx = forumLatestDiscussions.indexWhere(
        (d) => d.id == discussionId,
      );
      if (latestIdx != -1) {
        final topic = forumLatestDiscussions[latestIdx];
        // If page 0 returned less than size items, mergedLikers contains all real likers.
        // Sync upvotes with real backend reactions so count and list never mismatch.
        final alignedUpvotes = (page == 0 && likers.length < size)
            ? mergedLikers.length
            : (mergedLikers.length > topic.upvotes
                  ? mergedLikers.length
                  : topic.upvotes);
        forumLatestDiscussions[latestIdx] = topic.copyWith(
          likers: mergedLikers,
          upvotes: alignedUpvotes,
        );
        forumLatestDiscussions.refresh();
      }
      return mergedLikers;
    } catch (e) {
      rethrow;
    } finally {
      isLoadingDiscussionLikers[discussionId] = false;
    }
  }

  RxList<ForumTopicModel> get discussions => forumLatestDiscussions;

  Future<void> fetchDiscussions({bool isRefresh = false}) async {
    if (!isRefresh &&
        (isLoadingForumDiscussions.value ||
            isRefreshingForumDiscussions.value)) {
      return;
    }
    final requestGeneration = ++_discussionRequestGeneration;
    if (isRefresh) {
      isRefreshingForumDiscussions.value = true;
    } else {
      isLoadingForumDiscussions.value = true;
    }
    hasForumError.value = false;
    forumErrorMessage.value = '';

    try {
      final category = selectedForumCategory.value == 'All'
          ? null
          : selectedForumCategory.value;
      final fetchedPage = await repository.getDiscussionsPage(
        category: category,
        page: 1,
        limit: 20,
      );
      if (requestGeneration != _discussionRequestGeneration) return;
      final fetched = fetchedPage.content;
      for (final d in fetched) {
        discussionBookmarks[d.id] = d.isBookmarked;
      }
      discussionBookmarks.refresh();
      forumLatestDiscussions.assignAll(fetched);
      currentForumDiscussionsPage.value = 1;
      hasMoreForumDiscussions.value = fetchedPage.hasNext;
      hasMoreForumDiscussionsError.value = false;
      forumMoreErrorMessage.value = '';
    } catch (e) {
      if (requestGeneration != _discussionRequestGeneration) return;
      hasForumError.value = true;
      forumErrorMessage.value = e is AppError
          ? e.message
          : 'Couldn\'t load discussions. Try again.';
    } finally {
      if (requestGeneration == _discussionRequestGeneration) {
        isLoadingForumDiscussions.value = false;
        isRefreshingForumDiscussions.value = false;
      }
    }
  }

  Future<void> loadMoreDiscussions() async {
    if (isLoadingMoreForumDiscussions.value ||
        isLoadingForumDiscussions.value ||
        isRefreshingForumDiscussions.value ||
        !hasMoreForumDiscussions.value) {
      return;
    }
    isLoadingMoreForumDiscussions.value = true;
    final generation = _discussionRequestGeneration;
    final nextPage = currentForumDiscussionsPage.value + 1;
    try {
      final category = selectedForumCategory.value == 'All'
          ? null
          : selectedForumCategory.value;
      final fetched = await repository.getDiscussionsPage(
        category: category,
        page: nextPage,
        limit: 20,
      );
      if (generation != _discussionRequestGeneration) return;
      final seen = forumLatestDiscussions.map((item) => item.id).toSet();
      for (final discussion in fetched.content) {
        discussionBookmarks[discussion.id] = discussion.isBookmarked;
        if (seen.add(discussion.id)) forumLatestDiscussions.add(discussion);
      }
      discussionBookmarks.refresh();
      forumLatestDiscussions.refresh();
      currentForumDiscussionsPage.value = nextPage;
      hasMoreForumDiscussions.value = fetched.hasNext;
      hasMoreForumDiscussionsError.value = false;
      forumMoreErrorMessage.value = '';
    } catch (e) {
      if (generation == _discussionRequestGeneration) {
        hasMoreForumDiscussionsError.value = true;
        forumMoreErrorMessage.value = e is AppError
            ? e.message
            : 'Unable to load more discussions';
      }
    } finally {
      isLoadingMoreForumDiscussions.value = false;
    }
  }

  Future<bool> toggleDiscussionLike(String discussionId) async {
    if (discussionId.isEmpty) return false;
    if (inFlightDiscussionLikes.contains(discussionId)) return false;
    inFlightDiscussionLikes.add(discussionId);

    final latestIdx = forumLatestDiscussions.indexWhere(
      (d) => d.id == discussionId,
    );
    bool prevLiked = false;
    int prevUpvotes = 0;
    List<ForumLikerModel> prevLikers = [];

    if (latestIdx != -1) {
      final item = forumLatestDiscussions[latestIdx];
      prevLiked = item.isLiked;
      prevUpvotes = item.upvotes;
      prevLikers = List<ForumLikerModel>.from(
        discussionLikers[discussionId] ?? item.likers,
      );

      item.isLiked = !prevLiked;
      item.upvotes += item.isLiked ? 1 : -1;
      if (item.upvotes < 0) item.upvotes = 0;

      // We NEVER insert synthetic/mock current user into the likers list.
      // The likers list must strictly represent authentic backend reactions.
      forumLatestDiscussions[latestIdx] = item;
      forumLatestDiscussions.refresh();
    }

    try {
      final success = await repository.toggleDiscussionLike(
        discussionId,
        isCurrentlyLiked: prevLiked,
      );
      if (!success) {
        _rollbackDiscussionLike(
          discussionId,
          prevLiked,
          prevUpvotes,
          prevLikers,
        );
      } else {
        // Fetch authentic backend reactions and populate real likers ONLY if current user is owner
        final discussion = forumLatestDiscussions.firstWhereOrNull(
          (d) => d.id == discussionId,
        );
        final isOwner = discussion?.checkIsOwner(currentUserId) ?? false;
        if (isOwner) {
          await fetchDiscussionLikers(
            discussionId,
          ).catchError((_) => <ForumLikerModel>[]);
        }
      }
      return success;
    } catch (_) {
      _rollbackDiscussionLike(discussionId, prevLiked, prevUpvotes, prevLikers);
      return false;
    } finally {
      inFlightDiscussionLikes.remove(discussionId);
    }
  }

  void _rollbackDiscussionLike(
    String discussionId,
    bool prevLiked,
    int prevUpvotes, [
    List<ForumLikerModel>? prevLikers,
  ]) {
    final latestIdx = forumLatestDiscussions.indexWhere(
      (d) => d.id == discussionId,
    );
    if (latestIdx != -1) {
      final item = forumLatestDiscussions[latestIdx];
      item.isLiked = prevLiked;
      item.upvotes = prevUpvotes;
      if (prevLikers != null) {
        discussionLikers[discussionId] = prevLikers;
        discussionLikers.refresh();
      }
      forumLatestDiscussions[latestIdx] = item.copyWith(
        likers: prevLikers ?? item.likers,
      );
      forumLatestDiscussions.refresh();
    }
  }

  final RxMap<String, bool> discussionBookmarks = <String, bool>{}.obs;

  bool isDiscussionBookmarked(String discussionId) {
    if (discussionBookmarks.containsKey(discussionId)) {
      return discussionBookmarks[discussionId]!;
    }
    final item = forumLatestDiscussions.firstWhereOrNull(
      (d) => d.id == discussionId,
    );
    return item?.isBookmarked ?? false;
  }

  Future<bool> checkDiscussionBookmarkStatus(String discussionId) async {
    final saved = await repository.isDiscussionBookmarked(discussionId);
    discussionBookmarks[discussionId] = saved;
    final idx = forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
    if (idx != -1) {
      forumLatestDiscussions[idx] = forumLatestDiscussions[idx].copyWith(
        isBookmarked: saved,
      );
      forumLatestDiscussions.refresh();
    }
    return saved;
  }

  void clearBookmarkCache() {
    discussionBookmarks.clear();
    postBookmarks.clear();
  }

  Future<bool> toggleDiscussionBookmark(String discussionId) async {
    if (discussionId.trim().isEmpty) return false;

    final prevBookmarked = isDiscussionBookmarked(discussionId);
    final newStatus = !prevBookmarked;

    discussionBookmarks[discussionId] = newStatus;
    discussionBookmarks.refresh();

    final idx = forumLatestDiscussions.indexWhere((d) => d.id == discussionId);
    if (idx != -1) {
      forumLatestDiscussions[idx] = forumLatestDiscussions[idx].copyWith(
        isBookmarked: newStatus,
      );
      forumLatestDiscussions.refresh();
    }

    try {
      final success = await repository.toggleDiscussionBookmark(
        discussionId,
        isCurrentlyBookmarked: prevBookmarked,
      );
      if (!success) {
        _rollbackDiscussionBookmark(discussionId, prevBookmarked, idx);
        return false;
      }
      return true;
    } catch (_) {
      _rollbackDiscussionBookmark(discussionId, prevBookmarked, idx);
      return false;
    }
  }

  void _rollbackDiscussionBookmark(
    String discussionId,
    bool prevBookmarked,
    int idx,
  ) {
    discussionBookmarks[discussionId] = prevBookmarked;
    discussionBookmarks.refresh();
    if (idx != -1) {
      forumLatestDiscussions[idx] = forumLatestDiscussions[idx].copyWith(
        isBookmarked: prevBookmarked,
      );
      forumLatestDiscussions.refresh();
    }
  }

  Future<bool> repostDiscussion(
    ForumTopicModel discussion, {
    String? caption,
  }) async {
    final effectiveUserId =
        currentUserId ?? (CurrentUser.id.isNotEmpty ? CurrentUser.id : null);
    if (discussion.checkIsOwner(effectiveUserId)) {
      return false;
    }
    if (inFlightDiscussionReposts.contains(discussion.id)) {
      return false;
    }
    inFlightDiscussionReposts.add(discussion.id);

    final effectiveReposterId =
        (effectiveUserId != null && effectiveUserId.isNotEmpty)
        ? effectiveUserId
        : 'current_user';
    final normalizedCaption = caption?.trim();
    try {
      final effectiveCaption =
          normalizedCaption == null || normalizedCaption.isEmpty
          ? null
          : normalizedCaption;
      bool success;
      try {
        success = await repository.repostDiscussion(
          discussion.id,
          caption: effectiveCaption,
          reposterId: effectiveReposterId,
        );
      } on NoSuchMethodError {
        // Keep older repository fakes/source-compatible while production uses
        // the discussion-specific endpoint above.
        success = await repository.repostPost(
          discussion.id,
          caption: effectiveCaption,
          reposterId: effectiveReposterId,
        );
      }
      if (success) {
        _upsertDiscussionRepost(
          effectiveReposterId,
          discussion,
          caption: effectiveCaption,
        );
      }
      return success;
    } catch (e) {
      return false;
    } finally {
      inFlightDiscussionReposts.remove(discussion.id);
    }
  }

  Future<ForumTopicModel> addDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    if (isPublishingDiscussion.value) {
      throw AppError(
        message: 'Publishing already in progress',
        errorCode: 'DUPLICATE_PUBLISH',
      );
    }

    isPublishingDiscussion.value = true;
    try {
      var createdTopic = await repository.createDiscussion(
        title: title,
        content: content,
        category: category,
        anonymous: anonymous,
      );

      if (anonymous) {
        createdTopic = createdTopic.copyWith(
          isAnonymous: true,
          authorName: 'Anonymous',
          authorAvatar: '',
        );
      }

      forumLatestDiscussions.insert(0, createdTopic);
      forumLatestDiscussions.refresh();

      return createdTopic;
    } finally {
      isPublishingDiscussion.value = false;
    }
  }

  Future<bool> updateDiscussion({
    required String discussionId,
    required String title,
    required String content,
    required String category,
    bool? anonymous,
  }) async {
    try {
      var updatedTopic = await repository.updateDiscussion(
        discussionId,
        title: title,
        content: content,
        category: category,
        anonymous: anonymous,
      );

      if (anonymous == true ||
          (anonymous == null && updatedTopic.isAnonymous)) {
        updatedTopic = updatedTopic.copyWith(
          isAnonymous: true,
          authorName: 'Anonymous',
          authorAvatar: '',
        );
      }

      final forumIdx = forumLatestDiscussions.indexWhere(
        (d) => d.id == discussionId,
      );
      if (forumIdx != -1) {
        forumLatestDiscussions[forumIdx] = updatedTopic;
        forumLatestDiscussions.refresh();
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteDiscussion(String discussionId) async {
    try {
      final success = await repository.deleteDiscussion(discussionId);
      if (success) {
        forumLatestDiscussions.removeWhere((d) => d.id == discussionId);
        forumLatestDiscussions.refresh();
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  final isLoadingDiscussionDetail = false.obs;
  final discussionDetailError = ''.obs;

  Future<ForumTopicModel?> fetchDiscussionDetails(String discussionId) async {
    isLoadingDiscussionDetail.value = true;
    discussionDetailError.value = '';
    try {
      final detail = await repository.getDiscussionDetails(discussionId);
      discussionBookmarks[discussionId] = detail.isBookmarked;
      discussionBookmarks.refresh();

      final idx = forumLatestDiscussions.indexWhere(
        (d) => d.id == discussionId,
      );
      if (idx != -1) {
        forumLatestDiscussions[idx] = detail;
        forumLatestDiscussions.refresh();
      }
      return detail;
    } catch (e) {
      discussionDetailError.value = e is AppError
          ? e.message
          : 'Failed to load discussion details';
      return null;
    } finally {
      isLoadingDiscussionDetail.value = false;
    }
  }

  ForumTopicModel? getDiscussionById(String id) {
    return forumLatestDiscussions.firstWhereOrNull((d) => d.id == id);
  }

  @override
  void onInit() {
    super.onInit();
    if (_injectedRepository != null) {
      repository = _injectedRepository;
    } else if (Get.isRegistered<CommunityRepository>()) {
      repository = Get.find<CommunityRepository>();
    } else {
      final dio = Get.isRegistered<Dio>()
          ? Get.find<Dio>()
          : DioProvider.create();
      final dataSource = CommunityRemoteDataSource(dio: dio);
      repository = CommunityRepositoryImpl(remoteDataSource: dataSource);
    }

    scrollController.addListener(_onScrollListener);
    fetchPosts();
    fetchDiscussions();
    fetchEvents();
    fetchOpportunities();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _onScrollListener() {
    if (!scrollController.hasClients ||
        !scrollController.positions.any(
          (position) => position.pixels >= position.maxScrollExtent - 200,
        ) ||
        isLoadingMore.value ||
        isLoadingFeed.value ||
        !hasMorePosts.value ||
        selectedCategory.value != 'Feed') {
      return;
    }

    loadMorePosts();
  }

  void setCategory(String cat) {
    selectedCategory.value = cat;
    if (cat == 'Event' && events.isEmpty && !isLoadingEvents.value) {
      fetchEvents();
    }
  }

  void _syncAttachedEventsFromPosts(List<CommunityPostModel> feedPosts) {
    var changed = false;
    for (final post in feedPosts) {
      final attachedEvent = post.attachedEvent;
      if (attachedEvent == null) {
        final eventId = post.eventId;
        if (eventId != null && eventId.isNotEmpty) {
          unawaited(_hydrateEventForPost(post.id, eventId));
        }
        continue;
      }

      final existingIndex = events.indexWhere(
        (event) => event.id == attachedEvent.id,
      );
      if (existingIndex != -1) {
        events[existingIndex] = attachedEvent.copyWith();
        changed = true;
      } else {
        events.add(attachedEvent.copyWith());
        changed = true;
      }
    }
    if (changed) events.refresh();
  }

  Future<CommunityPostModel> _hydrateAttachedEvent(
    CommunityPostModel post,
  ) async {
    final eventId = post.eventId;
    if (eventId == null || eventId.isEmpty || post.attachedEvent != null) {
      return post;
    }
    try {
      final event = await repository.getEventDetails(eventId);
      _upsertEvent(events, event);
      return post.copyWith(attachedEvent: event);
    } catch (_) {
      // The detail endpoint is the visibility gate; keep the post's event ID,
      // but do not synthesize event details if the server denies access.
      return post;
    }
  }

  Future<void> _hydrateEventForPost(String postId, String eventId) async {
    final key = '$postId:$eventId';
    if (!_eventHydrationRequests.add(key)) return;
    try {
      final event = await repository.getEventDetails(eventId);
      _upsertEvent(events, event);
      final index = posts.indexWhere(
        (post) => post.id == postId && post.eventId == eventId,
      );
      if (index != -1) {
        posts[index] = posts[index].copyWith(attachedEvent: event);
      }
    } catch (_) {
      // The server decides whether this event is still visible.
    } finally {
      _eventHydrationRequests.remove(key);
    }
  }

  int? _durationDays(String? duration) {
    if (duration == null) return null;
    return int.tryParse(RegExp(r'\d+').firstMatch(duration)?.group(0) ?? '');
  }

  Future<void> fetchPosts({bool isRefresh = false}) {
    final inFlightLoad = _feedLoadFuture;
    if (!isRefresh && inFlightLoad != null) return inFlightLoad;

    final load = _fetchPosts(isRefresh: isRefresh);
    _feedLoadFuture = load;
    load.whenComplete(() {
      if (identical(_feedLoadFuture, load)) _feedLoadFuture = null;
    });
    return load;
  }

  Future<void> _fetchPosts({required bool isRefresh}) async {
    final requestGeneration = ++_feedRequestGeneration;
    if (isRefresh) {
      isRefreshingFeed.value = true;
    } else {
      isLoadingFeed.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';
    hasMorePostsError.value = false;
    morePostsErrorMessage.value = '';

    try {
      final fetched = await repository.getPosts(page: 1, limit: 10);
      if (requestGeneration != _feedRequestGeneration) return;
      currentPage.value = 1;
      posts.assignAll(fetched);
      _syncPostBookmarks(fetched);
      _syncAttachedEventsFromPosts(fetched);
      hasMorePosts.value = fetched.length >= 10;
      hasMorePostsError.value = false;
      morePostsErrorMessage.value = '';
      _syncFollowStates(fetched);
    } catch (e) {
      if (requestGeneration != _feedRequestGeneration) return;
      hasError.value = true;
      if (e is AppError) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Failed to load community feed.';
      }
    } finally {
      if (requestGeneration == _feedRequestGeneration) {
        isLoadingFeed.value = false;
        isRefreshingFeed.value = false;
      }
    }
  }

  Future<void> fetchRepostedPosts({bool force = false}) async {
    if (isLoadingRepostedPosts.value || (!force && _hasLoadedRepostedPosts)) {
      return;
    }

    isLoadingRepostedPosts.value = true;
    try {
      repostedPosts.assignAll(await repository.getRepostedPosts());
      _hasLoadedRepostedPosts = true;
    } catch (e) {
      debugPrint('[CommunityController] fetchRepostedPosts error: $e');
    } finally {
      isLoadingRepostedPosts.value = false;
    }
  }

  Future<void> fetchDiscussionReposts(
    String userId, {
    bool force = false,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty ||
        _inFlightDiscussionRepostUsers.contains(normalizedUserId) ||
        (!force && _loadedDiscussionRepostUsers.contains(normalizedUserId))) {
      return;
    }

    _inFlightDiscussionRepostUsers.add(normalizedUserId);
    isLoadingDiscussionReposts[normalizedUserId] = true;
    isLoadingDiscussionReposts.refresh();
    try {
      final fetched = await repository.getDiscussionReposts(
        userId: normalizedUserId,
        page: 1,
        limit: 20,
      );
      discussionRepostsByUser[normalizedUserId] = fetched;
      discussionRepostsByUser.refresh();
      _loadedDiscussionRepostUsers.add(normalizedUserId);
    } catch (e) {
      debugPrint('[CommunityController] fetchDiscussionReposts error: $e');
    } finally {
      _inFlightDiscussionRepostUsers.remove(normalizedUserId);
      isLoadingDiscussionReposts[normalizedUserId] = false;
      isLoadingDiscussionReposts.refresh();
    }
  }

  Future<CommunityPostModel?> fetchPostDetails(String postId) async {
    try {
      final post = await repository.getPostDetails(postId);
      final idx = posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        posts[idx] = post;
      }
      return post;
    } catch (e) {
      debugPrint('[COMMUNITY] fetchPostDetails failed for $postId: $e');
      rethrow;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value ||
        isLoadingFeed.value ||
        isRefreshingFeed.value ||
        !hasMorePosts.value) {
      return;
    }

    isLoadingMore.value = true;
    final requestGeneration = _feedRequestGeneration;
    hasMorePostsError.value = false;
    morePostsErrorMessage.value = '';
    try {
      final nextPage = currentPage.value + 1;
      final fetched = await repository.getPosts(page: nextPage, limit: 10);
      if (requestGeneration != _feedRequestGeneration) return;
      if (fetched.isNotEmpty) {
        for (final item in fetched) {
          final existingIdx = posts.indexWhere((p) => p.id == item.id);
          if (existingIdx == -1) {
            posts.add(item);
          }
        }
        _syncPostBookmarks(fetched);
        _syncAttachedEventsFromPosts(fetched);
        currentPage.value = nextPage;
        hasMorePosts.value = fetched.length >= 10;
        _syncFollowStates(fetched);
      } else {
        hasMorePosts.value = false;
      }
    } catch (e) {
      if (requestGeneration == _feedRequestGeneration) {
        hasMorePostsError.value = true;
        morePostsErrorMessage.value = e is AppError
            ? e.message
            : 'Couldn\'t load more posts. Try again.';
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshFeed() async {
    if (Get.isRegistered<StoryController>()) {
      Get.find<StoryController>().fetchStories();
    }
    await Future.wait([
      fetchPosts(isRefresh: true),
      fetchDiscussions(isRefresh: true),
      fetchEvents(isRefresh: true),
    ]);
  }

  Future<List<String>> _resolveImageUrls(List<String> rawUrls) async {
    final resolved = <String>[];
    final total = rawUrls.length;
    int index = 0;

    for (final img in rawUrls) {
      if (img.startsWith('http://') ||
          img.startsWith('https://') ||
          img.startsWith('assets/')) {
        resolved.add(img);
      } else {
        final file = File(img);
        if (await file.exists()) {
          final ext = img.split('.').last.toLowerCase();
          final contentType = (ext == 'png')
              ? 'image/png'
              : (ext == 'webp')
              ? 'image/webp'
              : 'image/jpeg';

          if (Get.isRegistered<MediaUploadService>()) {
            final uploadService = Get.find<MediaUploadService>();
            uploadService.validateFile(
              sizeBytes: await file.length(),
              contentType: contentType,
              purpose: MediaPurpose.post,
            );
            final bytes = await file.readAsBytes();
            final media = await uploadService.upload(
              bytes: bytes,
              contentType: contentType,
              purpose: MediaPurpose.post,
              onProgress: (frac) {
                if (total > 0) {
                  final base = index / total;
                  final step = 1.0 / total;
                  uploadProgress.value = 0.2 + (base + frac * step) * 0.6;
                }
              },
            );
            resolved.add(media.reference);
          } else {
            resolved.add(img);
          }
        } else {
          resolved.add(img);
        }
      }
      index++;
    }
    return resolved;
  }

  Future<String?> _resolveVideoUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('genlink-media://')) return rawUrl;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }

    try {
      final file = File(rawUrl);
      if (!await file.exists()) {
        debugPrint(
          '[CommunityController] Video file does not exist at path: $rawUrl',
        );
        throw AppError(
          message: 'Video file not found at $rawUrl',
          errorCode: 'MEDIA_FILE_NOT_FOUND',
        );
      }

      debugPrint(
        '[CommunityController] Uploading video from local path: $rawUrl, purpose: ${MediaPurpose.post}',
      );
      final path = rawUrl.toLowerCase();
      final contentType = path.endsWith('.mov')
          ? 'video/quicktime'
          : path.endsWith('.webm')
          ? 'video/webm'
          : 'video/mp4';
      if (!Get.isRegistered<MediaUploadService>()) {
        debugPrint(
          '[CommunityController] MediaUploadService not registered; aborting video upload',
        );
        throw const AppError(
          message: 'Media upload service is unavailable',
          errorCode: 'MEDIA_SERVICE_UNAVAILABLE',
        );
      }

      final uploadService = Get.find<MediaUploadService>();
      uploadService.validateFile(
        sizeBytes: await file.length(),
        contentType: contentType,
        purpose: MediaPurpose.post,
      );
      final bytes = await file.readAsBytes();
      final media = await uploadService.upload(
        bytes: bytes,
        contentType: contentType,
        purpose: MediaPurpose.post,
        onProgress: (fraction) {
          uploadProgress.value = 0.2 + fraction * 0.6;
        },
      );
      final mediaReference = media.reference;
      debugPrint(
        '[CommunityController] Video upload succeeded: $mediaReference',
      );
      return mediaReference;
    } catch (e) {
      debugPrint(
        '[CommunityController] Video upload failed for path: $rawUrl. Error: $e',
      );
      rethrow;
    }
  }

  Future<bool> addNewPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool allowMultipleAnswers = false,
    EventModel? attachedEvent,
  }) async {
    isUploadingPost.value = true;
    uploadProgress.value = 0.1;

    try {
      final resolvedImageUrls = await _resolveImageUrls(imageUrls);
      final resolvedVideoUrl = await _resolveVideoUrl(videoUrl);
      uploadProgress.value = 0.8;

      final createdPost = repository is RichCommunityRepository
          ? await (repository as RichCommunityRepository).createPostRich(
              content: content,
              imageUrls: resolvedImageUrls,
              videoUrl: resolvedVideoUrl,
              visibility: visibility,
              community: community,
              location: location,
              linkUrl: linkUrl,
              linkPreviewTitle: linkPreviewTitle,
              linkPreviewDomain: linkPreviewDomain,
              eventId: attachedEvent?.id,
            )
          : (resolvedVideoUrl == null
                ? await repository.createPost(
                    content: content,
                    imageUrls: resolvedImageUrls,
                    visibility: visibility,
                    community: community,
                  )
                : await repository.createPostWithVideo(
                    content: content,
                    imageUrls: resolvedImageUrls,
                    videoUrl: resolvedVideoUrl,
                    visibility: visibility,
                    community: community,
                  ));

      final richPost = await _hydrateAttachedEvent(createdPost);

      // A post can already be present when the create response races with a
      // feed refresh or another local update. Keep one list item per server ID
      // so image Hero tags cannot be duplicated by the feed data itself.
      final existingIdx = posts.indexWhere((post) => post.id == richPost.id);
      if (existingIdx == -1) {
        posts.insert(0, richPost);
      } else {
        posts[existingIdx] = richPost;
      }
      uploadProgress.value = 1.0;
      isUploadingPost.value = false;
      return true;
    } catch (e) {
      isUploadingPost.value = false;
      final errorText = e is AppError ? e.message : 'Could not publish post.';
      if (Get.context != null) {
        Get.snackbar(
          "Upload Failed",
          errorText,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.danger.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
      return false;
    }
  }

  final isCreatingPoll = false.obs;
  final inFlightPollVotes = <String>{}.obs;

  Future<bool> createPollPost({
    required String question,
    required List<String> options,
    String? caption,
    String visibility = 'Public',
    String? communityId,
    String? pollDuration,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    EventModel? attachedEvent,
  }) async {
    isCreatingPoll.value = true;
    try {
      final resolvedImages = await _resolveImageUrls(imageUrls);
      final resolvedVideo = await _resolveVideoUrl(videoUrl);
      final createdPost = repository is RichCommunityRepository
          ? await (repository as RichCommunityRepository).createPollPostRich(
              question: question,
              options: options,
              caption: caption,
              visibility: visibility,
              communityId: communityId,
              durationDays: _durationDays(pollDuration),
              imageUrls: resolvedImages,
              videoUrl: resolvedVideo,
              location: location,
              linkUrl: linkUrl,
              linkPreviewTitle: linkPreviewTitle,
              linkPreviewDomain: linkPreviewDomain,
              eventId: attachedEvent?.id,
            )
          : await repository.createPollPost(
              question: question,
              options: options,
              caption: caption,
              visibility: visibility,
              communityId: communityId,
            );
      final hydratedPost = await _hydrateAttachedEvent(createdPost);
      posts.insert(0, hydratedPost);
      posts.refresh();
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CommunityController] createPollPost error: $error');
      }
      return false;
    } finally {
      isCreatingPoll.value = false;
    }
  }

  Future<bool> votePoll(String postId, String optionId) async {
    if (inFlightPollVotes.contains(postId)) return false;

    final postIndex = posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return false;

    final originalPost = posts[postIndex];
    final previousOptions = originalPost.pollOptions == null
        ? <PollOptionModel>[]
        : List<PollOptionModel>.from(originalPost.pollOptions!);
    final previousTotalVotes = originalPost.pollTotalVotes;
    final previousHasVoted = originalPost.hasVoted;
    final previousOptionId = originalPost.myOptionId;

    if (previousHasVoted && previousOptionId == optionId) return true;

    inFlightPollVotes.add(postId);
    final updatedOptions = previousOptions.map((option) {
      final isNewChoice = option.id == optionId;
      final isOldChoice = option.id == previousOptionId;
      final updatedVotes = isNewChoice
          ? option.votes + 1
          : (isOldChoice && option.votes > 0 ? option.votes - 1 : option.votes);
      return option.copyWith(votes: updatedVotes, isVoted: isNewChoice);
    }).toList();

    posts[postIndex] = originalPost.copyWith(
      pollOptions: updatedOptions,
      pollTotalVotes: previousHasVoted
          ? previousTotalVotes
          : previousTotalVotes + 1,
      hasVoted: true,
      myOptionId: optionId,
    );
    posts.refresh();

    try {
      final updatedPost = await repository.votePoll(
        postId: postId,
        optionId: optionId,
      );
      final currentIndex = posts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) {
        final currentPost = posts[currentIndex];
        posts[currentIndex] = currentPost.copyWith(
          pollOptions: updatedPost.pollOptions ?? currentPost.pollOptions,
          pollTotalVotes: updatedPost.pollTotalVotes > 0
              ? updatedPost.pollTotalVotes
              : currentPost.pollTotalVotes,
          hasVoted: updatedPost.hasVoted,
          myOptionId: updatedPost.myOptionId ?? optionId,
        );
        posts.refresh();
      }
      return true;
    } catch (error) {
      final currentIndex = posts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) {
        posts[currentIndex] = originalPost.copyWith(
          pollOptions: previousOptions,
          pollTotalVotes: previousTotalVotes,
          hasVoted: previousHasVoted,
          myOptionId: previousOptionId,
        );
        posts.refresh();
      }
      if (kDebugMode) {
        debugPrint('[CommunityController] votePoll error: $error');
      }
      // Keep the optimistic state rollback above, then propagate the failure
      // so the poll widget can show its retry feedback to the user.
      rethrow;
    } finally {
      inFlightPollVotes.remove(postId);
    }
  }

  void toggleLike(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = posts[idx];
      final previousState = p.isLiked;
      final previousCount = p.likesCount;

      final nextState = !previousState;
      final nextCount = (previousCount + (nextState ? 1 : -1)).clamp(
        0,
        9999999,
      );
      p.isLiked = nextState;
      p.likesCount = nextCount;
      posts[idx] = p.copyWith(isLiked: nextState, likesCount: nextCount);
      posts.refresh();
      postLikers.remove(postId);

      final future = previousState
          ? repository.unlikePost(postId)
          : repository.toggleLike(postId);

      future.catchError((_) {
        final currentIdx = posts.indexWhere((item) => item.id == postId);
        if (currentIdx != -1) {
          final item = posts[currentIdx];
          item.isLiked = previousState;
          item.likesCount = previousCount;
          posts[currentIdx] = item.copyWith(
            isLiked: previousState,
            likesCount: previousCount,
          );
          posts.refresh();
          postLikers.remove(postId);
        }
        return false;
      });
    } else {
      postLikers.remove(postId);
      repository.toggleLike(postId).catchError((_) => false);
    }
  }

  final RxMap<String, bool> postBookmarks = <String, bool>{}.obs;
  final Set<String> _inFlightBookmarkUpdates = <String>{};

  bool isPostBookmarked(String postId) {
    if (postBookmarks.containsKey(postId)) {
      return postBookmarks[postId]!;
    }
    final item = posts.firstWhereOrNull((p) => p.id == postId);
    return item?.isBookmarked ?? false;
  }

  Future<bool> checkPostBookmarkStatus(String postId) async {
    final saved = await repository.isPostBookmarked(postId);
    postBookmarks[postId] = saved;
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      posts[idx] = posts[idx].copyWith(isBookmarked: saved);
      posts.refresh();
    }
    return saved;
  }

  void _syncPostBookmarks(List<CommunityPostModel> items) {
    for (final item in items) {
      postBookmarks[item.id] = item.isBookmarked;
    }
  }

  Future<bool> toggleBookmark(String postId) async {
    if (postId.trim().isEmpty) return false;
    if (!_inFlightBookmarkUpdates.add(postId)) return false;

    final prevBookmarked = isPostBookmarked(postId);
    final newStatus = !prevBookmarked;

    postBookmarks[postId] = newStatus;
    postBookmarks.refresh();

    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = posts[idx];
      p.isBookmarked = newStatus;
      posts[idx] = p.copyWith(isBookmarked: newStatus);
      posts.refresh();
    }

    try {
      final success = await repository.togglePostBookmark(
        postId,
        isCurrentlyBookmarked: prevBookmarked,
      );
      if (!success) {
        _rollbackBookmark(postId, prevBookmarked, idx);
        return false;
      }
      return true;
    } catch (error) {
      _rollbackBookmark(postId, prevBookmarked, idx);
      final message = error is AppError && error.message.isNotEmpty
          ? error.message
          : 'Could not update the saved post. Please try again.';
      if (Get.context != null) {
        Get.snackbar(
          'Bookmark update failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
      return false;
    } finally {
      _inFlightBookmarkUpdates.remove(postId);
    }
  }

  void _rollbackBookmark(String postId, bool prevBookmarked, [int? idx]) {
    postBookmarks[postId] = prevBookmarked;
    postBookmarks.refresh();
    final currentIdx =
        (idx != null &&
            idx != -1 &&
            idx < posts.length &&
            posts[idx].id == postId)
        ? idx
        : posts.indexWhere((item) => item.id == postId);
    if (currentIdx != -1) {
      final item = posts[currentIdx];
      item.isBookmarked = prevBookmarked;
      posts[currentIdx] = item.copyWith(isBookmarked: prevBookmarked);
      posts.refresh();
    }
  }

  Future<bool> deletePost(String postId) async {
    final idx = posts.indexWhere((p) => p.id == postId);
    final removed = idx == -1 ? null : posts.removeAt(idx);
    try {
      final succeeded = await repository.deletePost(postId);
      if (!succeeded) {
        throw const AppError(
          message: 'The post could not be deleted. Please try again.',
          errorCode: 'POST_DELETE_FAILED',
        );
      }
      return true;
    } catch (e) {
      if (removed != null && !posts.any((post) => post.id == postId)) {
        posts.insert(idx.clamp(0, posts.length), removed);
      }
      final message = e is AppError
          ? e.message
          : 'The post could not be deleted. Please try again.';
      Get.snackbar(
        'Post not deleted',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> editPost(String postId, String newContent) async {
    final updated = await repository.updatePost(postId, content: newContent);
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) posts[idx] = updated;
  }

  Future<void> editPostFull({
    required String postId,
    required String content,
    required List<String> imageUrls,
    String? videoUrl,
    required String visibility,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool? allowMultipleAnswers,
    EventModel? attachedEvent,
  }) async {
    final resolvedImageUrls = await _resolveImageUrls(imageUrls);
    final resolvedVideoUrl = await _resolveVideoUrl(videoUrl);
    final updated = repository is RichCommunityRepository
        ? await (repository as RichCommunityRepository).updatePostRich(
            postId,
            content: content,
            imageUrls: resolvedImageUrls,
            videoUrl: resolvedVideoUrl ?? '',
            visibility: visibility,
            location: location,
            linkUrl: linkUrl,
            linkPreviewTitle: linkPreviewTitle,
            linkPreviewDomain: linkPreviewDomain,
            pollQuestion: pollQuestion,
            pollOptions: pollOptions?.map((option) => option.text).toList(),
            pollDurationDays: _durationDays(pollDuration),
            eventId: attachedEvent?.id,
          )
        : await repository.updatePostFields(
            postId,
            content: content,
            imageUrls: resolvedImageUrls,
            videoUrl: resolvedVideoUrl ?? '',
            visibility: visibility,
          );
    final hydrated = await _hydrateAttachedEvent(updated);
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      posts[idx] = hydrated;
    }
  }

  Future<bool> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool allowMultipleAnswers = false,
    EventModel? attachedEvent,
  }) => addNewPost(
    content: content,
    imageUrls: imageUrls,
    videoUrl: videoUrl,
    visibility: visibility,
    community: community,
    location: location,
    linkUrl: linkUrl,
    linkPreviewTitle: linkPreviewTitle,
    linkPreviewDomain: linkPreviewDomain,
    pollQuestion: pollQuestion,
    pollOptions: pollOptions,
    pollDuration: pollDuration,
    allowMultipleAnswers: allowMultipleAnswers,
    attachedEvent: attachedEvent,
  );

  Future<void> updatePost({
    required String postId,
    required String content,
    required List<String> imageUrls,
    String? videoUrl,
    required String visibility,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool? allowMultipleAnswers,
    EventModel? attachedEvent,
  }) => editPostFull(
    postId: postId,
    content: content,
    imageUrls: imageUrls,
    videoUrl: videoUrl,
    visibility: visibility,
    location: location,
    linkUrl: linkUrl,
    linkPreviewTitle: linkPreviewTitle,
    linkPreviewDomain: linkPreviewDomain,
    pollQuestion: pollQuestion,
    pollOptions: pollOptions,
    pollDuration: pollDuration,
    allowMultipleAnswers: allowMultipleAnswers,
    attachedEvent: attachedEvent,
  );

  void repostPost(String postId, {String? caption}) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final original = posts[idx];

      if (original.checkIsOwner(currentUserId)) {
        return;
      }

      if (original.isRepostedByMe) {
        return;
      }

      final updated = original.copyWith(
        sharesCount: original.sharesCount + 1,
        isRepostedByMe: true,
        repostedBy: currentUserName,
        repostCaption: caption,
        reposterId: currentUserId,
        originalPostId: original.id,
      );
      posts[idx] = updated;
      _upsertRepostedPost(updated);

      repository
          .repostPost(postId, caption: caption, reposterId: currentUserId)
          .then<void>((success) {
            if (!success) {
              final revertIdx = posts.indexWhere((p) => p.id == postId);
              if (revertIdx != -1) {
                posts[revertIdx] = original;
              }
              _removeRepostedPost(postId);
            }
          })
          .catchError((_) {
            final revertIdx = posts.indexWhere((p) => p.id == postId);
            if (revertIdx != -1) {
              posts[revertIdx] = original;
            }
            _removeRepostedPost(postId);
          });
    } else {
      repository
          .repostPost(postId, caption: caption, reposterId: currentUserId)
          .then<void>((success) {
            if (success) fetchRepostedPosts(force: true);
          })
          .catchError((_) {});
    }
  }

  void unrepostPost(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final original = posts[idx];
      if (!original.isRepostedByMe) return;

      final updated = original.copyWith(
        sharesCount: original.sharesCount > 0 ? original.sharesCount - 1 : 0,
        clearRepostInfo: true,
      );
      posts[idx] = updated;
      _removeRepostedPost(postId);

      repository
          .unrepostPost(postId, reposterId: currentUserId)
          .then<void>((success) {
            if (!success) {
              final revertIdx = posts.indexWhere((p) => p.id == postId);
              if (revertIdx != -1) {
                posts[revertIdx] = original;
              }
              _upsertRepostedPost(original);
            }
          })
          .catchError((_) {
            final revertIdx = posts.indexWhere((p) => p.id == postId);
            if (revertIdx != -1) {
              posts[revertIdx] = original;
            }
            _upsertRepostedPost(original);
          });
    } else {
      final repostedIndex = repostedPosts.indexWhere((p) => p.id == postId);
      final repostedOriginal = repostedIndex == -1
          ? null
          : repostedPosts[repostedIndex];
      if (repostedOriginal != null) {
        _removeRepostedPost(postId);
      }
      repository
          .unrepostPost(postId, reposterId: currentUserId)
          .then<void>((success) {
            if (!success && repostedOriginal != null) {
              _upsertRepostedPost(repostedOriginal);
            }
          })
          .catchError((_) {
            if (repostedOriginal != null) {
              _upsertRepostedPost(repostedOriginal);
            }
          });
    }
  }

  Future<bool> reportPost(
    String postId, {
    String reason = 'INAPPROPRIATE_CONTENT',
  }) async {
    if (postId.trim().isEmpty || !_inFlightReports.add(postId)) return false;
    try {
      return await repository.reportPost(postId, reason: reason);
    } finally {
      _inFlightReports.remove(postId);
    }
  }

  final Set<String> _inFlightReports = <String>{};

  List<CommunityPostModel> getUserPosts(String userId, {String? username}) {
    // Prefer the repost copy because the same original may also be present in
    // the feed without the viewer-specific repost metadata.
    final candidates = <CommunityPostModel>[...repostedPosts, ...posts];
    final seenIds = <String>{};
    return candidates.where((p) {
      if (!seenIds.add(p.id)) return false;
      if (userId.isNotEmpty && p.userId == userId) {
        return true;
      }
      if (username != null &&
          username.isNotEmpty &&
          p.authorName.trim().toLowerCase() == username.trim().toLowerCase()) {
        return true;
      }
      if (p.reposterId == userId ||
          (p.isRepostedByMe && userId.isNotEmpty && userId == currentUserId) ||
          (p.repostedBy != null &&
              username != null &&
              p.repostedBy!.trim().toLowerCase() ==
                  username.trim().toLowerCase())) {
        return true;
      }
      return false;
    }).toList();
  }

  List<ForumTopicModel> getUserDiscussionReposts(String userId) {
    return discussionRepostsByUser[userId.trim()] ?? const <ForumTopicModel>[];
  }

  void _upsertDiscussionRepost(
    String userId,
    ForumTopicModel discussion, {
    String? caption,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final reposterName = currentUserName.trim().isNotEmpty
        ? currentUserName.trim()
        : 'You';
    final repostedTopic = discussion.copyWith(
      isRepostedByMe: true,
      repostedBy: reposterName,
      repostCaption: caption,
      reposterId: normalizedUserId,
    );
    final current = List<ForumTopicModel>.from(
      discussionRepostsByUser[normalizedUserId] ?? const <ForumTopicModel>[],
    );
    current.removeWhere((item) => item.id == discussion.id);
    current.insert(0, repostedTopic);
    discussionRepostsByUser[normalizedUserId] = current;
    discussionRepostsByUser.refresh();
    _loadedDiscussionRepostUsers.add(normalizedUserId);
  }

  void _upsertRepostedPost(CommunityPostModel post) {
    final index = repostedPosts.indexWhere((item) => item.id == post.id);
    if (index == -1) {
      repostedPosts.insert(0, post);
    } else {
      repostedPosts[index] = post;
    }
    repostedPosts.refresh();
  }

  void _removeRepostedPost(String postId) {
    repostedPosts.removeWhere((item) => item.id == postId);
  }

  Future<void> fetchComments(String postId) async {
    if (_activeCommentsPostId != postId) {
      activeComments.clear();
      _activeCommentsPostId = postId;
    }
    commentsErrorMessage.value = '';
    isLoadingComments.value = true;
    try {
      final comments = await repository.getComments(postId);
      activeComments.assignAll(comments);
    } catch (e) {
      debugPrint('[CommunityController] fetchComments error: $e');
      commentsErrorMessage.value = e is AppError
          ? e.message
          : 'Couldn\'t load comments. Try again.';
    } finally {
      isLoadingComments.value = false;
    }
  }

  final discussionComments = <String, List<CommentModel>>{}.obs;
  final discussionCommentsErrors = <String, String>{}.obs;
  final isLoadingDiscussionComments = false.obs;
  final isSendingDiscussionComment = false.obs;

  List<CommentModel> getCommentsForDiscussion(String discussionId) {
    return discussionComments[discussionId] ?? [];
  }

  Future<void> fetchDiscussionComments(String discussionId) async {
    isLoadingDiscussionComments.value = true;
    discussionCommentsErrors.remove(discussionId);
    try {
      final comments = await repository.getDiscussionComments(discussionId);
      discussionComments[discussionId] = comments;
      discussionComments.refresh();
    } catch (e) {
      discussionCommentsErrors[discussionId] = e is AppError
          ? e.message
          : 'Couldn\'t load comments. Try again.';
      discussionCommentsErrors.refresh();
    } finally {
      isLoadingDiscussionComments.value = false;
    }
  }

  Future<CommentModel?> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || isSendingDiscussionComment.value) return null;

    isSendingDiscussionComment.value = true;
    try {
      final comment = await repository.addDiscussionComment(
        discussionId,
        trimmed,
        parentCommentId: parentCommentId,
      );
      final current = List<CommentModel>.from(
        discussionComments[discussionId] ?? [],
      );
      final effectiveParentId = comment.parentCommentId ?? parentCommentId;
      if (effectiveParentId != null && effectiveParentId.isNotEmpty) {
        final parentIndex = current.indexWhere(
          (item) =>
              item.id == effectiveParentId ||
              item.replies.any((reply) => reply.id == effectiveParentId),
        );
        if (parentIndex != -1 && current[parentIndex].id == effectiveParentId) {
          final parent = current[parentIndex];
          current[parentIndex] = parent.copyWith(
            replies: [...parent.replies, comment],
          );
        } else {
          current.add(comment);
        }
      } else {
        current.add(comment);
      }
      discussionComments[discussionId] = current;
      discussionComments.refresh();

      final forumIdx = forumLatestDiscussions.indexWhere(
        (d) => d.id == discussionId,
      );
      if (forumIdx != -1) {
        final topic = forumLatestDiscussions[forumIdx];
        topic.repliesCount += 1;
        forumLatestDiscussions[forumIdx] = topic.copyWith();
        forumLatestDiscussions.refresh();
      }

      return comment;
    } catch (e) {
      rethrow;
    } finally {
      isSendingDiscussionComment.value = false;
    }
  }

  Future<bool> toggleDiscussionCommentLike(
    String discussionId,
    String commentId,
  ) async {
    if (inFlightCommentLikes.contains(commentId)) return false;
    inFlightCommentLikes.add(commentId);

    final comments = discussionComments[discussionId];
    if (comments == null) {
      inFlightCommentLikes.remove(commentId);
      return false;
    }

    CommentModel? targetComment;
    final cIdx = comments.indexWhere((comment) => comment.id == commentId);
    if (cIdx != -1) {
      targetComment = comments[cIdx];
    } else {
      for (final parent in comments) {
        final replyIndex = parent.replies.indexWhere(
          (reply) => reply.id == commentId,
        );
        if (replyIndex != -1) {
          targetComment = parent.replies[replyIndex];
          break;
        }
      }
    }

    if (targetComment == null) {
      inFlightCommentLikes.remove(commentId);
      return false;
    }

    final prevLiked = targetComment.isLiked;
    final prevLikesCount = targetComment.likesCount;

    targetComment.isLiked = !prevLiked;
    targetComment.likesCount += targetComment.isLiked ? 1 : -1;
    discussionComments.refresh();

    try {
      final success = await repository.toggleDiscussionCommentLike(
        commentId,
        isCurrentlyLiked: prevLiked,
      );
      if (!success) {
        targetComment.isLiked = prevLiked;
        targetComment.likesCount = prevLikesCount;
        discussionComments.refresh();
      }
      return success;
    } catch (_) {
      targetComment.isLiked = prevLiked;
      targetComment.likesCount = prevLikesCount;
      discussionComments.refresh();
      return false;
    } finally {
      inFlightCommentLikes.remove(commentId);
    }
  }

  Future<CommentModel?> updateDiscussionComment(
    String discussionId,
    String commentId,
    String content,
  ) async {
    try {
      final updatedComment = await repository.updateDiscussionComment(
        commentId,
        content,
      );
      final current = List<CommentModel>.from(
        discussionComments[discussionId] ?? [],
      );
      final topLevelIndex = current.indexWhere(
        (comment) => comment.id == commentId,
      );
      if (topLevelIndex != -1) {
        current[topLevelIndex] = updatedComment.copyWith(
          replies: updatedComment.replies.isNotEmpty
              ? updatedComment.replies
              : current[topLevelIndex].replies,
        );
      } else {
        for (var i = 0; i < current.length; i++) {
          final parent = current[i];
          final replyIndex = parent.replies.indexWhere(
            (reply) => reply.id == commentId,
          );
          if (replyIndex != -1) {
            final updatedReplies = List<CommentModel>.from(parent.replies);
            updatedReplies[replyIndex] = updatedComment;
            current[i] = parent.copyWith(replies: updatedReplies);
            break;
          }
        }
      }
      discussionComments[discussionId] = current;
      discussionComments.refresh();
      return updatedComment;
    } catch (_) {
      // Keep the old comment untouched and let the editor show the server error.
      rethrow;
    }
  }

  Future<bool> deleteDiscussionComment(
    String discussionId,
    String commentId,
  ) async {
    try {
      final success = await repository.deleteDiscussionComment(commentId);
      if (success) {
        final current = List<CommentModel>.from(
          discussionComments[discussionId] ?? [],
        );
        final topLevelIndex = current.indexWhere(
          (comment) => comment.id == commentId,
        );
        if (topLevelIndex != -1) {
          current.removeAt(topLevelIndex);
        } else {
          for (var i = 0; i < current.length; i++) {
            final parent = current[i];
            if (parent.replies.any((reply) => reply.id == commentId)) {
              current[i] = parent.copyWith(
                replies: parent.replies
                    .where((reply) => reply.id != commentId)
                    .toList(),
              );
              break;
            }
          }
        }
        discussionComments[discussionId] = current;
        discussionComments.refresh();

        final forumIdx = forumLatestDiscussions.indexWhere(
          (d) => d.id == discussionId,
        );
        if (forumIdx != -1) {
          final topic = forumLatestDiscussions[forumIdx];
          if (topic.repliesCount > 0) {
            topic.repliesCount -= 1;
            forumLatestDiscussions[forumIdx] = topic.copyWith();
            forumLatestDiscussions.refresh();
          }
        }
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reportDiscussion(
    String discussionId, {
    String reason = 'INAPPROPRIATE_CONTENT',
    String? details,
  }) async {
    try {
      return await repository.reportDiscussion(
        discussionId,
        reason: reason,
        details: details,
      );
    } catch (_) {
      return false;
    }
  }

  bool _attachReplyToTree(
    CommentModel root,
    String targetParentId,
    CommentModel reply,
    void Function(CommentModel) onUpdate,
  ) {
    if (root.id == targetParentId) {
      final updatedReplies = List<CommentModel>.from(root.replies);
      if (!updatedReplies.any((r) => r.id == reply.id)) {
        updatedReplies.add(reply);
      }
      onUpdate(root.copyWith(replies: updatedReplies));
      return true;
    }
    for (int i = 0; i < root.replies.length; i++) {
      final child = root.replies[i];
      if (_attachReplyToTree(child, targetParentId, reply, (updatedChild) {
        final updatedReplies = List<CommentModel>.from(root.replies);
        updatedReplies[i] = updatedChild;
        onUpdate(root.copyWith(replies: updatedReplies));
      })) {
        return true;
      }
    }
    return false;
  }

  CommentModel _removeCommentFromReplies(
    CommentModel comment,
    String targetId,
  ) {
    if (comment.replies.isEmpty) return comment;
    final updated = comment.replies
        .where((r) => r.id != targetId)
        .map((r) => _removeCommentFromReplies(r, targetId))
        .toList();
    return comment.copyWith(replies: updated);
  }

  bool _toggleCommentLikeInTree(
    CommentModel node,
    String targetId,
    void Function(CommentModel) onUpdate,
  ) {
    if (node.id == targetId) {
      node.isLiked = !node.isLiked;
      node.likesCount += node.isLiked ? 1 : -1;
      onUpdate(node);
      return true;
    }
    for (int i = 0; i < node.replies.length; i++) {
      final child = node.replies[i];
      if (_toggleCommentLikeInTree(child, targetId, (updatedChild) {
        final updatedReplies = List<CommentModel>.from(node.replies);
        updatedReplies[i] = updatedChild;
        onUpdate(node.copyWith(replies: updatedReplies));
      })) {
        return true;
      }
    }
    return false;
  }

  Future<CommentModel?> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final comment = await repository.addComment(
        postId,
        trimmed,
        parentCommentId: parentCommentId,
      );

      final effectiveParentId = comment.parentCommentId ?? parentCommentId;
      if (effectiveParentId != null && effectiveParentId.isNotEmpty) {
        bool attached = false;
        for (int i = 0; i < activeComments.length; i++) {
          final root = activeComments[i];
          if (_attachReplyToTree(root, effectiveParentId, comment, (
            updatedRoot,
          ) {
            activeComments[i] = updatedRoot;
          })) {
            attached = true;
            break;
          }
        }
        if (!attached) {
          activeComments.add(comment);
        }
      } else {
        activeComments.add(comment);
      }
      activeComments.refresh();

      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final p = posts[idx];
        p.commentsCount += 1;
        posts[idx] = p.copyWith();
        posts.refresh();
      }
      return comment;
    } catch (e) {
      debugPrint('[CommunityController] addComment error: $e');
      rethrow;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final success = await repository.deleteComment(postId, commentId);
      if (success) {
        activeComments.removeWhere((c) => c.id == commentId);
        for (var i = 0; i < activeComments.length; i++) {
          final parent = activeComments[i];
          activeComments[i] = _removeCommentFromReplies(parent, commentId);
        }
        activeComments.refresh();

        final idx = posts.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          final p = posts[idx];
          if (p.commentsCount > 0) {
            p.commentsCount -= 1;
            posts[idx] = p.copyWith();
            posts.refresh();
          }
        }
      }
      return success;
    } catch (e) {
      debugPrint('[CommunityController] deleteComment error: $e');
      rethrow;
    }
  }

  void toggleCommentLike(String postId, String commentId) {
    for (int i = 0; i < activeComments.length; i++) {
      final root = activeComments[i];
      if (_toggleCommentLikeInTree(root, commentId, (updatedRoot) {
        activeComments[i] = updatedRoot;
        activeComments.refresh();
      })) {
        return;
      }
    }
  }

  void toggleGroupJoin(String groupId) {
    final idx = recommendedGroups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      recommendedGroups[idx].isJoined = !recommendedGroups[idx].isJoined;
      recommendedGroups.refresh();
    }
  }

  bool isOwnUserId(String userId) {
    final currentId = currentUserId;
    if (currentId != null && currentId.isNotEmpty) {
      return currentId == userId;
    }
    return false;
  }

  bool isFollowingUser(String userId) {
    final post = posts.firstWhereOrNull((p) => p.userId == userId);
    if (post != null) return post.isFollowing;
    final suggested = suggestedUsers.firstWhereOrNull((u) => u.id == userId);
    if (suggested != null) return suggested.isFollowing;
    return false;
  }

  void _setFollowStateForUser(String userId, bool isFollowing) {
    bool postUpdated = false;
    for (int i = 0; i < posts.length; i++) {
      if (posts[i].userId == userId) {
        posts[i] = posts[i].copyWith(isFollowing: isFollowing);
        postUpdated = true;
      }
    }
    if (postUpdated) {
      posts.refresh();
    }

    final suggestedIdx = suggestedUsers.indexWhere((u) => u.id == userId);
    if (suggestedIdx != -1) {
      suggestedUsers[suggestedIdx].isFollowing = isFollowing;
      suggestedUsers.refresh();
    }
  }

  Future<void> _syncFollowStates(List<CommunityPostModel> postList) async {
    final uniqueAuthorIds = postList
        .map((p) => p.userId)
        .where((id) => id.isNotEmpty && !isOwnUserId(id))
        .toSet();

    for (final authorId in uniqueAuthorIds) {
      try {
        final isFollowing = await repository.checkIsFollowing(authorId);
        _setFollowStateForUser(authorId, isFollowing);
      } catch (_) {}
    }
  }

  Future<bool> toggleFollowUser(String userId) async {
    if (userId.isEmpty) return false;

    if (isOwnUserId(userId)) {
      return false;
    }

    if (followLoadingUserIds.contains(userId)) {
      return false;
    }

    final currentlyFollowing = isFollowingUser(userId);
    final targetState = !currentlyFollowing;

    followLoadingUserIds.add(userId);

    _setFollowStateForUser(userId, targetState);

    try {
      final success = currentlyFollowing
          ? await repository.unfollowUser(userId)
          : await repository.followUser(userId);

      if (!success) {
        throw AppError(
          message: 'Failed to update follow status',
          errorCode: 'FOLLOW_FAILED',
        );
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().refreshFollowStats();
      }
      return true;
    } catch (e) {
      _setFollowStateForUser(userId, currentlyFollowing);

      final errorMsg = e is AppError ? e.message : 'common.error'.tr;
      Get.snackbar(
        'community.follow'.tr,
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      followLoadingUserIds.remove(userId);
    }
  }

  void toggleUserFollow(String userId) => toggleFollowUser(userId);

  DateTime? _lastFeedTapRefreshTime;

  Future<void> onFeedTabTappedAgain() async {
    scrollToTop();
    final now = DateTime.now();
    if (_lastFeedTapRefreshTime != null &&
        now.difference(_lastFeedTapRefreshTime!).inMilliseconds < 800) {
      return;
    }
    if (isLoadingFeed.value || isRefreshingFeed.value) return;
    _lastFeedTapRefreshTime = now;
    await refreshFeed();
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }
}
