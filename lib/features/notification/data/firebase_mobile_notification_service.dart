import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../firebase_options.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../community/presentation/screens/events_screen.dart';
import '../../community/presentation/screens/friend_requests_screen.dart';
import '../../finance/finance_screen.dart';
import '../../finance/presentation/budget_feature/budget_screen.dart';
import '../../finance/presentation/saving_goal_feature/saving_goals_screen.dart';
import '../../productivity/presentation/focus_feature/focus_home_screen.dart';
import '../../productivity/presentation/habit_feature/habit_screen.dart';
import '../../productivity/presentation/task_feature/task_home_screen.dart';
import '../../productivity/productivity_screen.dart';
import '../../chat/presentation/controllers/chat_controller.dart';
import '../../chat/chat_navigation.dart';

import '../presentation/controllers/notification_controller.dart';

const _mobilePushChannelId = 'genlink_mobile_push';
const _mobilePushChannelName = 'GenLink notifications';
const _mobilePushChannelDescription =
    'Notifications about GenLink events and account activity.';

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  _mobilePushChannelId,
  _mobilePushChannelName,
  description: _mobilePushChannelDescription,
  importance: Importance.high,
);

const AndroidInitializationSettings _androidInitializationSettings =
    AndroidInitializationSettings('ic_stat_genlink');

const DarwinInitializationSettings _darwinInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

const InitializationSettings _initializationSettings = InitializationSettings(
  android: _androidInitializationSettings,
  iOS: _darwinInitializationSettings,
);

const NotificationDetails _notificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _mobilePushChannelId,
    _mobilePushChannelName,
    channelDescription: _mobilePushChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_stat_genlink',
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  ),
);

bool _isMobilePlatform() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// The FCM data contract sent by the backend for a mobile notification.
class MobilePushNotificationPayload {
  const MobilePushNotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    this.deliveryId,
    this.referenceType,
    this.referenceId,
    this.dedupeKey,
  });

  final String title;
  final String body;
  final String type;
  final String? deliveryId;
  final String? referenceType;
  final String? referenceId;
  final String? dedupeKey;

  factory MobilePushNotificationPayload.fromRemoteMessage(
    RemoteMessage message,
  ) {
    return MobilePushNotificationPayload.fromData(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  factory MobilePushNotificationPayload.fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    String? value(String key) {
      final raw = data[key];
      if (raw == null) return null;
      final normalized = raw.toString().trim();
      return normalized.isEmpty ? null : normalized;
    }

    return MobilePushNotificationPayload(
      title: _firstNonBlank(title, value('title')) ?? 'GenLink KH',
      body:
          _firstNonBlank(body, value('body')) ?? 'You have a new notification.',
      type: value('type') ?? 'SYSTEM',
      deliveryId: value('deliveryId'),
      referenceType: value('referenceType'),
      referenceId: value('referenceId'),
      dedupeKey: value('dedupeKey'),
    );
  }

  factory MobilePushNotificationPayload.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return MobilePushNotificationPayload.fromData(
      data,
      title: json['title']?.toString(),
      body: json['body']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'data': {
        'type': type,
        if (deliveryId != null) 'deliveryId': deliveryId,
        if (referenceType != null) 'referenceType': referenceType,
        if (referenceId != null) 'referenceId': referenceId,
        if (dedupeKey != null) 'dedupeKey': dedupeKey,
      },
    };
  }

  int get notificationId {
    final source = deliveryId ?? dedupeKey ?? '$type:$referenceId';
    return source.codeUnits.fold<int>(17, (hash, codeUnit) {
      return ((hash * 31) + codeUnit) & 0x7fffffff;
    });
  }

  static String? _firstNonBlank(String? first, String? second) {
    for (final candidate in [first, second]) {
      final normalized = candidate?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return null;
  }
}

enum MobilePushNotificationDestination {
  notifications,
  challenges,
  events,
  friendRequests,
  finance,
  budget,
  savingGoals,
  productivity,
  habits,
  tasks,
  goals,
  quiz,
  achievements,
  chat,
}

/// Maps backend reference metadata to screens that already exist in Flutter.
class MobilePushNotificationRouter {
  const MobilePushNotificationRouter._();

  static MobilePushNotificationDestination destinationFor(
    MobilePushNotificationPayload payload,
  ) {
    final reference = _normalize(payload.referenceType);
    final type = _normalize(payload.type);

    switch (reference) {
      case 'EVENT':
        return MobilePushNotificationDestination.events;
      case 'FRIENDREQUEST':
        return MobilePushNotificationDestination.friendRequests;
      case 'CHAT':
      case 'CHATROOM':
        return MobilePushNotificationDestination.chat;
      case 'BUDGET':
        return MobilePushNotificationDestination.budget;
      case 'SAVINGGOAL':
        return MobilePushNotificationDestination.savingGoals;
      case 'TASK':
        return MobilePushNotificationDestination.tasks;
      case 'HABIT':
        return MobilePushNotificationDestination.habits;
      case 'GOAL':
        return MobilePushNotificationDestination.goals;
      case 'QUIZ':
        return MobilePushNotificationDestination.quiz;
      case 'ACHIEVEMENT':
        return MobilePushNotificationDestination.achievements;
      case 'BADGE':
        return MobilePushNotificationDestination.achievements;
      case 'CHALLENGE':
        return MobilePushNotificationDestination.challenges;
    }

    if (type.contains('CHAT')) {
      return MobilePushNotificationDestination.chat;
    }
    if (type.contains('CHALLENGE')) {
      return MobilePushNotificationDestination.challenges;
    }
    if (type.contains('EVENT')) {
      return MobilePushNotificationDestination.events;
    }
    if (type.contains('FRIENDREQUEST') || type.contains('FOLLOW')) {
      return MobilePushNotificationDestination.friendRequests;
    }
    if (type.contains('BUDGET')) {
      return MobilePushNotificationDestination.budget;
    }
    if (type.contains('SAVINGGOAL')) {
      return MobilePushNotificationDestination.savingGoals;
    }
    if (type.contains('TASK')) {
      return MobilePushNotificationDestination.tasks;
    }
    if (type.contains('HABIT')) {
      return MobilePushNotificationDestination.habits;
    }
    if (type.contains('GOAL')) {
      return MobilePushNotificationDestination.goals;
    }
    if (type.contains('QUIZ')) {
      return MobilePushNotificationDestination.quiz;
    }
    if (type.contains('ACHIEVEMENT')) {
      return MobilePushNotificationDestination.achievements;
    }
    if (type.contains('BADGE') || type.contains('LEVELUP')) {
      return MobilePushNotificationDestination.achievements;
    }
    if (type.contains('FINANCE')) {
      return MobilePushNotificationDestination.finance;
    }
    if (type.contains('PRODUCTIVITY')) {
      return MobilePushNotificationDestination.productivity;
    }
    return MobilePushNotificationDestination.notifications;
  }

  static Future<void> navigate(MobilePushNotificationPayload payload) async {
    switch (destinationFor(payload)) {
      case MobilePushNotificationDestination.notifications:
        Get.toNamed<void>(AppRoutes.notifications);
      case MobilePushNotificationDestination.challenges:
        final challengeId = payload.referenceId;
        if (challengeId != null && challengeId.isNotEmpty) {
          Get.toNamed<void>(AppRoutes.challengeDetail, arguments: challengeId);
        } else {
          Get.toNamed<void>(AppRoutes.challengeList);
        }
      case MobilePushNotificationDestination.chat:
        final roomId = payload.referenceId;
        if (roomId != null && roomId.isNotEmpty) {
          ChatNavigation.openChatDetail(roomId);
        } else {
          Get.toNamed<void>(AppRoutes.chat);
        }

      case MobilePushNotificationDestination.events:
        Get.to<void>(() => const EventsScreen());
            case MobilePushNotificationDestination.friendRequests:
        Get.to<void>(() => FriendRequestsScreen(highlightUserId: payload.referenceId));
      case MobilePushNotificationDestination.finance:
        Get.to<void>(() => const FinanceScreen());
      case MobilePushNotificationDestination.budget:
        Get.to<void>(() => const BudgetScreen());
      case MobilePushNotificationDestination.savingGoals:
        Get.to<void>(() => const SavingGoalsScreen());
      case MobilePushNotificationDestination.productivity:
        Get.to<void>(() => const ProductivityPage());
      case MobilePushNotificationDestination.habits:
        Get.to<void>(() => const HabitHomeScreen());
      case MobilePushNotificationDestination.tasks:
        Get.to<void>(() => const TasksPage());
      case MobilePushNotificationDestination.goals:
        Get.to<void>(() => const FocusPage());
      case MobilePushNotificationDestination.quiz:
        Get.toNamed<void>(AppRoutes.quizDashboard);
      case MobilePushNotificationDestination.achievements:
        Get.toNamed<void>(AppRoutes.profileAchievements);
    }
  }

  static String _normalize(String? value) =>
      (value ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

/// Handles FCM foreground messages and taps from background/terminated states.
class FirebaseMobileNotificationService {
  FirebaseMobileNotificationService({
    this.messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    Future<void> Function(MobilePushNotificationPayload payload)? onTap,
  }) : _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _onTap = onTap ?? MobilePushNotificationRouter.navigate;

  final FirebaseMessaging? messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Future<void> Function(MobilePushNotificationPayload payload) _onTap;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Future<void>? _initialization;
  MobilePushNotificationPayload? _pendingTap;
  bool _tapDispatchScheduled = false;

  static void registerBackgroundHandler() {
    if (_isMobilePlatform()) {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMobileMessagingBackgroundHandler,
      );
    }
  }

  Future<void> initialize() => _initialization ??= _initialize().whenComplete(
    () => _initialization = null,
  );

  Future<void> _initialize() async {
    if (!_isMobilePlatform()) return;
    if (Firebase.apps.isEmpty) {
      debugPrint(
        '[FCM] Firebase is not initialized; display handling skipped.',
      );
      return;
    }

    try {
      registerBackgroundHandler();
      await _localNotifications.initialize(
        settings: _initializationSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationResponse,
      );
      await _createAndroidChannel();
      await _requestAndroidPermission();

      _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showForegroundNotification(message));
      });
      _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
        _handleRemoteMessageTap,
      );

      final messagingClient = messaging ?? FirebaseMessaging.instance;
      final initialMessage = await messagingClient.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageTap(initialMessage);
      }

      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _handleLocalNotificationTap(
          launchDetails?.notificationResponse?.payload,
        );
      }
      debugPrint('[FCM] Notification display and tap handling initialized.');
    } catch (error, stackTrace) {
      debugPrint(
        '[FCM] Notification handling initialization failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _createAndroidChannel() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestAndroidPermission() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final payload = MobilePushNotificationPayload.fromRemoteMessage(message);
    try {
      await _localNotifications.show(
        id: payload.notificationId,
        title: payload.title,
        body: payload.body,
        notificationDetails: _notificationDetails,
        payload: jsonEncode(payload.toJson()),
      );
      debugPrint(
        '[FCM] Foreground notification shown type=${payload.type} '
        'deliveryId=${payload.deliveryId ?? 'none'}',
      );

      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>()
            .onRealtimeNotificationReceivedFromPayload(payload);
      }
      final isChat =
          payload.type.toUpperCase().contains('CHAT') ||
          (payload.referenceType?.toUpperCase() == 'CHAT_ROOM') ||
          (payload.referenceType?.toUpperCase() == 'CHAT');
      if (isChat && Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().fetchUnreadCount();
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[FCM] Foreground notification display failed: $error\n$stackTrace',
      );
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _dispatchTap(MobilePushNotificationPayload.fromRemoteMessage(message));
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    _handleLocalNotificationTap(response.payload);
  }

  void _handleLocalNotificationTap(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return;
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map) {
        _dispatchTap(
          MobilePushNotificationPayload.fromJson(
            Map<String, dynamic>.from(decoded),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[FCM] Notification tap payload is invalid: $error\n$stackTrace',
      );
    }
  }

  void _dispatchTap(MobilePushNotificationPayload payload) {
    _pendingTap = payload;
    if (_tapDispatchScheduled) return;
    _tapDispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tapDispatchScheduled = false;
      final pending = _pendingTap;
      _pendingTap = null;
      if (pending == null) return;
      if (!_isAppReadyForNavigation()) {
        _pendingTap = pending;
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (_pendingTap == pending) _dispatchTap(pending);
        });
        return;
      }
      unawaited(_invokeTap(pending));
    });
  }

  bool _isAppReadyForNavigation() {
    if (Get.context == null) return false;
    if (!Get.isRegistered<AuthController>()) return true;

    final auth = Get.find<AuthController>();
    return auth.isAuthenticated.value && Get.currentRoute != AppRoutes.splash;
  }

  Future<void> _invokeTap(MobilePushNotificationPayload payload) async {
    try {
      await _onTap(payload);
    } catch (error, stackTrace) {
      debugPrint('[FCM] Notification tap handling failed: $error\n$stackTrace');
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _foregroundSubscription = null;
    _openedSubscription = null;
  }
}

/// Handles data-only FCM messages in a background isolate.
///
/// Current backend messages include a notification payload, so Android renders
/// them automatically while backgrounded. This handler is kept for future
/// data-only messages and deliberately avoids duplicating system-rendered ones.
@pragma('vm:entry-point')
Future<void> firebaseMobileMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (!_isMobilePlatform()) return;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (message.notification != null) return;

    final payload = MobilePushNotificationPayload.fromRemoteMessage(message);
    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.initialize(settings: _initializationSettings);
    final android = localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_androidChannel);
    await localNotifications.show(
      id: payload.notificationId,
      title: payload.title,
      body: payload.body,
      notificationDetails: _notificationDetails,
      payload: jsonEncode(payload.toJson()),
    );
  } catch (error, stackTrace) {
    debugPrint(
      '[FCM] Background notification handling failed: $error\n$stackTrace',
    );
  }
}
