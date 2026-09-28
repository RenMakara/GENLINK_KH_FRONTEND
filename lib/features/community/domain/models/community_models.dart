// ignore: depend_on_referenced_packages
import 'dart:io';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/utils/current_user.dart';
export 'event_requests.dart';
export 'opportunity_model.dart';
import 'event_requests.dart';

class EventModel {
  final String id;
  final String title;
  final String subtitle;
  final String organizerName;
  final String? organizerUsername;
  final String? organizerId;
  final String? organizerAvatar;

  /// 'Online' or 'In person'
  final String eventType;

  /// Backend mode string: 'ONLINE' or 'IN_PERSON'
  final String? mode;

  /// Physical address — used when eventType == 'In person'
  final String location;

  /// Backend location name
  final String? locationName;

  /// URL — used when eventType == 'Online'
  final String onlineLink;

  /// Backend meeting URL
  final String? meetingUrl;

  final double? latitude;
  final double? longitude;

  final String dateString;
  final String timeString;
  final DateTime? startDateTime;
  final DateTime? endDateTime;

  final String description;
  final String category;
  final bool isPaid;
  final double? price;
  final double priceKhr;
  final String? currency;

  /// Network URL or empty string for placeholder
  final String imageUrl;

  /// Local gallery file — used immediately after creation before any upload
  final File? coverImageFile;

  final int? attendeeLimit;
  int attendeesCount;
  final String status;
  final String language;
  String? myRsvpStatus; // mutable — updated after RSVP response
  bool isRsvped;
  final bool isFull;
  bool isBookmarked;
  final List<String> attendeeAvatars;

  EventModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.organizerName = '',
    this.organizerUsername,
    this.organizerId,
    this.organizerAvatar,
    this.eventType = 'In person',
    this.mode,
    this.location = '',
    this.locationName,
    this.onlineLink = '',
    this.meetingUrl,
    this.latitude,
    this.longitude,
    this.dateString = '',
    this.timeString = '',
    this.startDateTime,
    this.endDateTime,
    this.description = '',
    this.category = '',
    this.isPaid = false,
    this.price,
    this.priceKhr = 0.0,
    this.currency,
    this.imageUrl = '',
    this.coverImageFile,
    this.attendeeLimit,
    this.attendeesCount = 0,
    this.status = 'PUBLISHED',
    this.language = 'ENGLISH',
    this.myRsvpStatus,
    this.isRsvped = false,
    this.isFull = false,
    this.isBookmarked = false,
    this.attendeeAvatars = const [],
  });

  EventMode get eventMode => EventMode.fromString(mode ?? eventType);

  bool get isOnline {
    if (mode != null) {
      return mode!.toUpperCase() == 'ONLINE';
    }
    if (eventType.toLowerCase().contains('online')) return true;
    return eventMode == EventMode.online;
  }

  bool get isInPerson {
    if (mode != null) {
      final m = mode!.toUpperCase();
      return m == 'IN_PERSON' || m == 'INPERSON';
    }
    if (eventType.toLowerCase().contains('person') ||
        eventType.toLowerCase().contains('campus')) {
      return true;
    }
    return eventMode == EventMode.inPerson;
  }

  String get effectiveLocation {
    if (isOnline) {
      // The backend deliberately omits meetingUrl for users who cannot access
      // it. Never use a legacy/public link field as a fallback here.
      return effectiveLocationName;
    } else {
      if (locationName != null && locationName!.trim().isNotEmpty) {
        return locationName!.trim();
      }
      return location;
    }
  }

  String get effectiveLocationName {
    if (locationName != null && locationName!.trim().isNotEmpty) {
      return locationName!.trim();
    }
    if (location.isNotEmpty) return location;
    return '';
  }

  String get effectiveMeetingUrl {
    if (meetingUrl != null && meetingUrl!.trim().isNotEmpty) {
      return meetingUrl!.trim();
    }
    return '';
  }

  String get normalizedStatus => status.trim().toUpperCase();

  bool get isDraft => normalizedStatus == 'DRAFT';

  bool get isPublished => normalizedStatus == 'PUBLISHED';

  bool get isCancelled => normalizedStatus == 'CANCELLED';

  bool get isCompleted => normalizedStatus == 'COMPLETED';

  bool get hasStarted =>
      startDateTime != null && !startDateTime!.isAfter(DateTime.now());

  bool get isPast => hasStarted;

  bool get isRsvpEligible =>
      isPublished &&
      (startDateTime == null || startDateTime!.isAfter(DateTime.now()));

  bool get hasJoinedRsvp =>
      isRsvped || myRsvpStatus?.trim().toUpperCase() == 'JOINED';

  bool isOwnedBy(String? userId) =>
      userId != null && userId.isNotEmpty && organizerId == userId;

  bool canAccessMeetingFor(String? userId) =>
      isOwnedBy(userId) || hasJoinedRsvp;

  static const _enMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _kmMonths = [
    'មករា',
    'កុម្ភៈ',
    'មីនា',
    'មេសា',
    'ឧសភា',
    'មិថុនា',
    'កក្កដា',
    'សីហា',
    'កញ្ញា',
    'តុលា',
    'វិច្ឆិកា',
    'ធ្នូ',
  ];

  String get formattedStartDate {
    if (startDateTime == null) return '';
    return '${startDateTime!.day} ${_enMonths[startDateTime!.month - 1]} ${startDateTime!.year}';
  }

  String get formattedEndDate {
    if (endDateTime == null) return '';
    return '${endDateTime!.day} ${_enMonths[endDateTime!.month - 1]} ${endDateTime!.year}';
  }

  String get formattedDateRange {
    if (startDateTime == null) return '';
    if (endDateTime == null ||
        (startDateTime!.year == endDateTime!.year &&
            startDateTime!.month == endDateTime!.month &&
            startDateTime!.day == endDateTime!.day)) {
      return formattedStartDate;
    }
    if (startDateTime!.year == endDateTime!.year &&
        startDateTime!.month == endDateTime!.month) {
      return '${startDateTime!.day}–${endDateTime!.day} ${_enMonths[startDateTime!.month - 1]} ${startDateTime!.year}';
    }
    if (startDateTime!.year == endDateTime!.year) {
      return '${startDateTime!.day} ${_enMonths[startDateTime!.month - 1]} – ${endDateTime!.day} ${_enMonths[endDateTime!.month - 1]} ${startDateTime!.year}';
    }
    return '$formattedStartDate – $formattedEndDate';
  }

  String get formattedStartTime {
    if (startDateTime == null) return '';
    final hour = startDateTime!.hour;
    final minute = startDateTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$minute $period';
  }

  String get formattedEndTime {
    if (endDateTime == null) return '';
    final hour = endDateTime!.hour;
    final minute = endDateTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$minute $period';
  }

  String get formattedTimeRange {
    if (startDateTime == null) return '';
    if (endDateTime == null) return formattedStartTime;
    return '$formattedStartTime – $formattedEndTime';
  }

  String formatLocalizedDateRange(bool isKhmer) {
    if (!isKhmer) {
      final range = formattedDateRange;
      if (range.isNotEmpty) return range;
      return dateString.isNotEmpty ? dateString : 'Date TBC';
    }
    if (startDateTime == null) {
      return dateString.isNotEmpty ? dateString : 'Date TBC';
    }
    final yearKh = _toKhmerDigits(startDateTime!.year);
    if (endDateTime == null ||
        (startDateTime!.year == endDateTime!.year &&
            startDateTime!.month == endDateTime!.month &&
            startDateTime!.day == endDateTime!.day)) {
      return '${startDateTime!.day} ${_kmMonths[startDateTime!.month - 1]} $yearKh';
    }
    if (startDateTime!.year == endDateTime!.year &&
        startDateTime!.month == endDateTime!.month) {
      return '${startDateTime!.day}–${endDateTime!.day} ${_kmMonths[startDateTime!.month - 1]} $yearKh';
    }
    return '${startDateTime!.day} ${_kmMonths[startDateTime!.month - 1]} $yearKh – ${endDateTime!.day} ${_kmMonths[endDateTime!.month - 1]} ${_toKhmerDigits(endDateTime!.year)}';
  }

  String formatLocalizedTimeRange(bool isKhmer) {
    if (!isKhmer) {
      final range = formattedTimeRange;
      if (range.isNotEmpty) return range;
      return timeString;
    }
    if (startDateTime == null) return timeString;
    final startH = startDateTime!.hour;
    final startM = startDateTime!.minute.toString().padLeft(2, '0');
    final startH12 = startH % 12 == 0 ? 12 : startH % 12;
    final startPeriod = startH >= 12 ? 'ល្ងាច' : 'ព្រឹក';
    final startStr = '$startH12:$startM $startPeriod';

    if (endDateTime == null) return startStr;
    final endH = endDateTime!.hour;
    final endM = endDateTime!.minute.toString().padLeft(2, '0');
    final endH12 = endH % 12 == 0 ? 12 : endH % 12;
    final endPeriod = endH >= 12 ? 'ល្ងាច' : 'ព្រឹក';
    final endStr = '$endH12:$endM $endPeriod';

    return '$startStr – $endStr';
  }

  static String _toKhmerDigits(int number) {
    const khDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    return number
        .toString()
        .split('')
        .map((c) {
          final d = int.tryParse(c);
          return d != null ? khDigits[d] : c;
        })
        .join('');
  }

  static String _formatThousands(num number) {
    final parts = number.toString().split('.');
    final intPart = parts[0];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    if (parts.length > 1) {
      return '$formattedInt.${parts[1]}';
    }
    return formattedInt;
  }

  String get formattedPrice {
    if (!isPaid) return 'Free';
    final effectiveP = price ?? priceKhr;
    if (currency == 'USD') {
      final pStr = effectiveP % 1 == 0
          ? effectiveP.toInt().toString()
          : effectiveP.toStringAsFixed(2);
      return '\$$pStr USD';
    } else if (currency == 'KHR') {
      final formatted = _formatThousands(effectiveP.toInt());
      return '$formatted ៛';
    } else if (currency == null) {
      return '\$${effectiveP.toStringAsFixed(2)}';
    } else {
      final pStr = effectiveP % 1 == 0
          ? effectiveP.toInt().toString()
          : effectiveP.toStringAsFixed(2);
      return '$pStr $currency';
    }
  }

  String get displayPriceString {
    if (!isPaid) return 'Free Entry';
    final effectiveP = price ?? priceKhr;
    if (currency == 'USD') {
      final pStr = effectiveP % 1 == 0
          ? effectiveP.toInt().toString()
          : effectiveP.toStringAsFixed(2);
      return '\$$pStr USD';
    } else if (currency == 'KHR') {
      final formatted = _formatThousands(effectiveP.toInt());
      return '$formatted KHR';
    } else if (currency != null && currency!.isNotEmpty) {
      final pStr = effectiveP % 1 == 0
          ? effectiveP.toInt().toString()
          : effectiveP.toStringAsFixed(2);
      return '$pStr $currency';
    } else {
      return '${effectiveP.toInt()} KHR';
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.trim().isNotEmpty) {
        return DateTime.tryParse(val.trim());
      }
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String && val.trim().isNotEmpty) {
        return double.tryParse(val.trim());
      }
      return null;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String && val.trim().isNotEmpty) {
        return int.tryParse(val.trim());
      }
      return null;
    }

    final organizerObj = json['organizer'] is Map<String, dynamic>
        ? json['organizer'] as Map<String, dynamic>
        : (json['creator'] is Map<String, dynamic>
              ? json['creator'] as Map<String, dynamic>
              : (json['user'] is Map<String, dynamic>
                    ? json['user'] as Map<String, dynamic>
                    : (json['author'] is Map<String, dynamic>
                          ? json['author'] as Map<String, dynamic>
                          : (json['owner'] is Map<String, dynamic>
                                ? json['owner'] as Map<String, dynamic>
                                : (json['host'] is Map<String, dynamic>
                                      ? json['host'] as Map<String, dynamic>
                                      : null)))));

    final createdByObj = json['createdBy'] is Map<String, dynamic>
        ? json['createdBy'] as Map<String, dynamic>
        : (json['created_by'] is Map<String, dynamic>
              ? json['created_by'] as Map<String, dynamic>
              : null);

    final isBackendOwner =
        json['isOwner'] == true ||
        json['is_owner'] == true ||
        json['isOrganizer'] == true ||
        json['is_organizer'] == true ||
        json['canEdit'] == true ||
        json['can_edit'] == true;

    final rawOrgId =
        json['organizerId']?.toString() ??
        json['organizer_id']?.toString() ??
        json['creatorId']?.toString() ??
        json['creator_id']?.toString() ??
        json['userId']?.toString() ??
        json['user_id']?.toString() ??
        json['authorId']?.toString() ??
        json['author_id']?.toString() ??
        json['ownerId']?.toString() ??
        json['owner_id']?.toString() ??
        json['hostId']?.toString() ??
        json['host_id']?.toString() ??
        json['accountId']?.toString() ??
        json['account_id']?.toString() ??
        (json['organizer'] is! Map ? json['organizer']?.toString() : null) ??
        (json['creator'] is! Map ? json['creator']?.toString() : null) ??
        (json['user'] is! Map ? json['user']?.toString() : null) ??
        (json['author'] is! Map ? json['author']?.toString() : null) ??
        (json['owner'] is! Map ? json['owner']?.toString() : null) ??
        (json['host'] is! Map ? json['host']?.toString() : null) ??
        (json['createdBy'] is! Map ? json['createdBy']?.toString() : null) ??
        (json['created_by'] is! Map ? json['created_by']?.toString() : null) ??
        organizerObj?['id']?.toString() ??
        organizerObj?['userId']?.toString() ??
        organizerObj?['user_id']?.toString() ??
        organizerObj?['uuid']?.toString() ??
        organizerObj?['_id']?.toString() ??
        organizerObj?['sub']?.toString() ??
        createdByObj?['id']?.toString() ??
        createdByObj?['userId']?.toString() ??
        createdByObj?['user_id']?.toString() ??
        createdByObj?['uuid']?.toString() ??
        createdByObj?['_id']?.toString() ??
        createdByObj?['sub']?.toString();

    final currentUserId = CurrentUser.id.trim();
    String? orgId = (rawOrgId != null && rawOrgId.trim().isNotEmpty)
        ? rawOrgId.trim()
        : null;

    if (orgId == null || orgId.isEmpty) {
      if (isBackendOwner && currentUserId.isNotEmpty) {
        orgId = currentUserId;
      } else if (currentUserId.isNotEmpty) {
        final currentUsername = CurrentUser.username.trim();
        final currentEmail = CurrentUser.get()?.email.trim() ?? '';
        final orgUsername =
            (organizerObj?['username'] ?? organizerObj?['userName'])
                ?.toString()
                .trim();
        final orgEmail = (organizerObj?['email'])?.toString().trim();
        if ((orgUsername != null &&
                orgUsername.isNotEmpty &&
                orgUsername.toLowerCase() == currentUsername.toLowerCase()) ||
            (orgEmail != null &&
                orgEmail.isNotEmpty &&
                orgEmail.toLowerCase() == currentEmail.toLowerCase())) {
          orgId = currentUserId;
        }
      }
    }

    final rawOrgUsername =
        (organizerObj?['username'] ??
                organizerObj?['userName'] ??
                createdByObj?['username'] ??
                createdByObj?['userName'] ??
                json['organizerUsername'] ??
                json['organizer_username'] ??
                json['creatorUsername'] ??
                json['authorUsername'])
            ?.toString()
            .trim();
    final cleanOrgUsername =
        (rawOrgUsername != null && rawOrgUsername.isNotEmpty)
        ? rawOrgUsername
        : null;

    final orgName =
        organizerObj?['fullName'] as String? ??
        organizerObj?['username'] as String? ??
        organizerObj?['name'] as String? ??
        organizerObj?['displayName'] as String? ??
        createdByObj?['fullName'] as String? ??
        createdByObj?['username'] as String? ??
        createdByObj?['name'] as String? ??
        json['organizerName'] as String? ??
        json['organizer_name'] as String? ??
        json['creatorName'] as String? ??
        json['authorName'] as String? ??
        json['userName'] as String? ??
        '';
    final orgAvatar =
        organizerObj?['avatarUrl'] as String? ??
        organizerObj?['avatar'] as String? ??
        organizerObj?['profileImage'] as String? ??
        organizerObj?['profileImageUrl'] as String? ??
        organizerObj?['profilePicture'] as String? ??
        organizerObj?['picture'] as String? ??
        organizerObj?['image'] as String? ??
        createdByObj?['avatarUrl'] as String? ??
        createdByObj?['avatar'] as String? ??
        json['organizerAvatar'] as String? ??
        json['organizerAvatarUrl'] as String? ??
        json['avatarUrl'] as String? ??
        json['profileImage'] as String? ??
        json['profileImageUrl'] as String? ??
        json['picture'] as String?;
    final cleanOrgAvatar = (orgAvatar != null && orgAvatar.trim().isNotEmpty)
        ? orgAvatar.trim()
        : null;

    final parsedStart =
        parseDt(json['startDateTime']) ?? parseDt(json['dateTime']);
    final parsedEnd = parseDt(json['endDateTime']);

    final modeVal = json['mode'] as String?;
    final eventTypeVal =
        json['eventType'] as String? ??
        (modeVal != null
            ? (modeVal.toUpperCase() == 'ONLINE'
                  ? 'Online'
                  : ((modeVal.toUpperCase() == 'IN_PERSON' ||
                            modeVal.toUpperCase() == 'INPERSON')
                        ? 'In person'
                        : modeVal))
            : 'In person');

    final locName = json['locationName'] as String?;
    final loc = json['location'] as String? ?? locName ?? '';

    final meetUrl = json['meetingUrl'] as String?;
    // `onlineLink` is retained only for legacy local/demo objects. The real
    // backend contract uses meetingUrl and may intentionally return null.
    final onLink = json['onlineLink'] as String? ?? '';

    final isPaidVal = json['paid'] as bool? ?? json['isPaid'] as bool? ?? false;
    final parsedPrice = parseDouble(json['price']);
    final curr = json['currency'] as String?;
    final pKhr = (curr == 'KHR' && parsedPrice != null)
        ? parsedPrice
        : (parseDouble(json['priceKhr']) ??
              (isPaidVal ? (parsedPrice ?? 0.0) : 0.0));

    final rsvpStatus = json['myRsvpStatus']?.toString();
    final isRsvpedVal =
        json['isRsvped'] as bool? ??
        (rsvpStatus != null && rsvpStatus.toUpperCase() == 'JOINED');

    final isFullVal = json['full'] as bool? ?? json['isFull'] as bool? ?? false;

    final idVal = json['eventId']?.toString() ?? json['id']?.toString() ?? '';

    final event = EventModel(
      id: idVal,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      organizerName: orgName,
      organizerUsername: cleanOrgUsername,
      organizerId: orgId,
      organizerAvatar: cleanOrgAvatar,
      eventType: eventTypeVal,
      mode: modeVal,
      location: loc,
      locationName: locName,
      onlineLink: onLink,
      meetingUrl: meetUrl,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      dateString: json['dateString'] as String? ?? '',
      timeString: json['timeString'] as String? ?? '',
      startDateTime: parsedStart,
      endDateTime: parsedEnd,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isPaid: isPaidVal,
      price: parsedPrice,
      priceKhr: pKhr,
      currency: curr,
      imageUrl:
          json['coverImageUrl'] as String? ?? json['imageUrl'] as String? ?? '',
      attendeeLimit: parseInt(json['attendeeLimit']),
      attendeesCount:
          parseInt(json['attendeeCount']) ??
          parseInt(json['attendeesCount']) ??
          0,
      status: json['status'] as String? ?? 'PUBLISHED',
      language: json['language'] as String? ?? 'ENGLISH',
      myRsvpStatus: rsvpStatus,
      isRsvped: isRsvpedVal,
      isFull: isFullVal,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      attendeeAvatars:
          (json['attendeeAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );

    // If dateString or timeString are empty but startDateTime exists, populate them
    if (event.dateString.isEmpty && event.startDateTime != null) {
      return event.copyWith(
        dateString: event.formattedDateRange,
        timeString: event.formattedTimeRange,
      );
    }
    return event;
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': id,
      'title': title,
      if (subtitle.isNotEmpty) 'subtitle': subtitle,
      if (organizerId != null) 'organizerId': organizerId,
      if (organizerUsername != null && organizerUsername!.isNotEmpty)
        'organizerUsername': organizerUsername,
      if (organizerName.isNotEmpty) 'organizerName': organizerName,
      if (organizerAvatar != null && organizerAvatar!.isNotEmpty)
        'organizerAvatar': organizerAvatar,
      'description': description,
      'category': category,
      if (imageUrl.isNotEmpty) 'coverImageUrl': imageUrl,
      if (startDateTime != null)
        'startDateTime': startDateTime!.toIso8601String(),
      if (endDateTime != null) 'endDateTime': endDateTime!.toIso8601String(),
      if (mode != null) 'mode': mode,
      'eventType': eventType,
      if (locationName != null) 'locationName': locationName,
      'location': location,
      if (meetingUrl != null) 'meetingUrl': meetingUrl,
      'onlineLink': onlineLink,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (attendeeLimit != null) 'attendeeLimit': attendeeLimit,
      'attendeeCount': attendeesCount,
      'status': status,
      'language': language,
      'paid': isPaid,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (myRsvpStatus != null) 'myRsvpStatus': myRsvpStatus,
      'full': isFull,
      'isBookmarked': isBookmarked,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? organizerName,
    String? organizerUsername,
    String? organizerId,
    String? organizerAvatar,
    String? eventType,
    String? mode,
    String? location,
    String? locationName,
    String? onlineLink,
    String? meetingUrl,
    double? latitude,
    double? longitude,
    String? dateString,
    String? timeString,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? description,
    String? category,
    bool? isPaid,
    double? price,
    double? priceKhr,
    String? currency,
    String? imageUrl,
    File? coverImageFile,
    int? attendeeLimit,
    int? attendeesCount,
    String? status,
    String? language,
    String? myRsvpStatus,
    bool? isRsvped,
    bool? isFull,
    bool? isBookmarked,
    List<String>? attendeeAvatars,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      organizerName: organizerName ?? this.organizerName,
      organizerUsername: organizerUsername ?? this.organizerUsername,
      organizerId: organizerId ?? this.organizerId,
      organizerAvatar: organizerAvatar ?? this.organizerAvatar,
      eventType: eventType ?? this.eventType,
      mode: mode ?? this.mode,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      onlineLink: onlineLink ?? this.onlineLink,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateString: dateString ?? this.dateString,
      timeString: timeString ?? this.timeString,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      description: description ?? this.description,
      category: category ?? this.category,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      priceKhr: priceKhr ?? this.priceKhr,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      coverImageFile: coverImageFile ?? this.coverImageFile,
      attendeeLimit: attendeeLimit ?? this.attendeeLimit,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      status: status ?? this.status,
      language: language ?? this.language,
      myRsvpStatus: myRsvpStatus ?? this.myRsvpStatus,
      isRsvped: isRsvped ?? this.isRsvped,
      isFull: isFull ?? this.isFull,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
    );
  }
}

class ForumLikerModel {
  final String id;
  final String fullName;
  final String username;
  final String avatarUrl;

  const ForumLikerModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl = '',
  });

  factory ForumLikerModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['author'] is Map<String, dynamic>
              ? json['author'] as Map<String, dynamic>
              : null);
    final id =
        (json['id'] ??
                json['userId'] ??
                userObj?['id'] ??
                userObj?['userId'] ??
                '')
            .toString();
    final fullName =
        (json['fullName'] ??
                json['name'] ??
                userObj?['fullName'] ??
                userObj?['name'] ??
                'User')
            .toString();
    final rawUsername = (json['username'] ?? userObj?['username'] ?? fullName)
        .toString();
    final username = rawUsername.startsWith('@')
        ? rawUsername
        : '@$rawUsername';
    final avatarUrl =
        (json['avatarUrl'] ??
                json['avatar'] ??
                userObj?['avatarUrl'] ??
                userObj?['avatar'] ??
                '')
            .toString();

    return ForumLikerModel(
      id: id,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'username': username,
    'avatarUrl': avatarUrl,
  };
}

class PostLikerModel {
  final String id;
  final String fullName;
  final String username;
  final String avatarUrl;

  const PostLikerModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl = '',
  });

  factory PostLikerModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['author'] is Map<String, dynamic>
              ? json['author'] as Map<String, dynamic>
              : null);
    final id =
        (json['id'] ??
                json['userId'] ??
                userObj?['id'] ??
                userObj?['userId'] ??
                '')
            .toString();
    final fullName =
        (json['fullName'] ??
                json['name'] ??
                userObj?['fullName'] ??
                userObj?['name'] ??
                'User')
            .toString();
    final rawUsername = (json['username'] ?? userObj?['username'] ?? fullName)
        .toString();
    final username = rawUsername.startsWith('@')
        ? rawUsername
        : '@$rawUsername';
    final avatarUrl =
        (json['avatarUrl'] ??
                json['avatar'] ??
                userObj?['avatarUrl'] ??
                userObj?['avatar'] ??
                '')
            .toString();

    return PostLikerModel(
      id: id,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': id,
    'fullName': fullName,
    'username': username,
    'avatarUrl': avatarUrl,
  };
}

class ForumTopicModel {
  final String id;
  final String? authorId;
  final String title;
  final String authorName;
  final String authorAvatar;
  final String category;
  final String content;
  int upvotes;
  int repliesCount;
  final String timeAgo;
  final DateTime? createdAt;
  bool isLiked;
  final bool isPinned;
  final bool isOwner;
  final bool isAnonymous;
  final List<ForumLikerModel> likers;
  final bool isRepostedByMe;
  final String? repostedBy;
  final String? repostCaption;
  final String? reposterId;

  ForumTopicModel({
    required this.id,
    String? authorId,
    required this.title,
    required String authorName,
    String authorAvatar = '',
    required this.category,
    required this.content,
    this.upvotes = 0,
    this.repliesCount = 0,
    required this.timeAgo,
    this.createdAt,
    this.isLiked = false,
    this.isPinned = false,
    this.isOwner = false,
    this.isAnonymous = false,
    this.isBookmarked = false,
    this.likers = const [],
    this.isRepostedByMe = false,
    this.repostedBy,
    this.repostCaption,
    this.reposterId,
  }) : authorId = isAnonymous ? null : authorId,
       authorName = isAnonymous ? 'Anonymous' : authorName,
       authorAvatar = isAnonymous ? '' : authorAvatar;

  final bool isBookmarked;
  bool get mine => isOwner;

  /// Evaluates whether the given user ID matches this discussion's author ID.
  /// Uses stable author ID comparison when available, and respects session ownership.
  bool checkIsOwner(String? currentUserId) {
    if (isOwner) return true;
    if (authorId != null && authorId!.isNotEmpty) {
      if (currentUserId != null && currentUserId.isNotEmpty) {
        return authorId == currentUserId;
      }
    }
    return isOwner;
  }

  ForumTopicModel copyWith({
    String? id,
    String? authorId,
    String? title,
    String? authorName,
    String? authorAvatar,
    String? category,
    String? content,
    int? upvotes,
    int? repliesCount,
    String? timeAgo,
    DateTime? createdAt,
    bool? isLiked,
    bool? isPinned,
    bool? isOwner,
    bool? isAnonymous,
    bool? isBookmarked,
    List<ForumLikerModel>? likers,
    bool? isRepostedByMe,
    String? repostedBy,
    String? repostCaption,
    String? reposterId,
  }) {
    final effectiveAnonymous = isAnonymous ?? this.isAnonymous;
    return ForumTopicModel(
      id: id ?? this.id,
      authorId: effectiveAnonymous ? null : (authorId ?? this.authorId),
      title: title ?? this.title,
      authorName: effectiveAnonymous
          ? 'Anonymous'
          : (authorName ?? this.authorName),
      authorAvatar: effectiveAnonymous
          ? ''
          : (authorAvatar ?? this.authorAvatar),
      category: category ?? this.category,
      content: content ?? this.content,
      upvotes: upvotes ?? this.upvotes,
      repliesCount: repliesCount ?? this.repliesCount,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      isPinned: isPinned ?? this.isPinned,
      isOwner: isOwner ?? this.isOwner,
      isAnonymous: effectiveAnonymous,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      likers: likers ?? this.likers,
      isRepostedByMe: isRepostedByMe ?? this.isRepostedByMe,
      repostedBy: repostedBy ?? this.repostedBy,
      repostCaption: repostCaption ?? this.repostCaption,
      reposterId: reposterId ?? this.reposterId,
    );
  }

  factory ForumTopicModel.fromJson(Map<String, dynamic> json) {
    final rawAnonymous =
        json['anonymous'] as bool? ?? json['isAnonymous'] as bool?;
    final authorObj = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : null;
    final isAnonymous =
        rawAnonymous ??
        (authorObj == null && json['authorName'] == 'Anonymous');

    final authorName = isAnonymous
        ? 'Anonymous'
        : (authorObj?['fullName'] as String? ??
              authorObj?['username'] as String? ??
              json['authorName'] as String? ??
              json['username'] as String? ??
              'User');
    final authorAvatar = isAnonymous
        ? ''
        : (authorObj?['avatarUrl'] as String? ??
              json['authorAvatar'] as String? ??
              '');
    final authorId = isAnonymous
        ? null
        : (authorObj?['userId'] as String? ??
              json['authorId'] as String? ??
              json['userId'] as String?);

    final rawDate = json['createdAt'] as String? ?? json['timeAgo'] as String?;
    final parsedUtc = CommunityDateFormatter.parseToUtc(rawDate);
    final formattedTime = formatCommunityTimestamp(
      parsedUtc ?? rawDate ?? 'Just now',
    );

    final rawLikers =
        json['likers'] as List<dynamic>? ??
        json['recentReactions'] as List<dynamic>? ??
        json['reactions'] as List<dynamic>?;
    final parsedLikers = rawLikers != null
        ? rawLikers
              .whereType<Map<String, dynamic>>()
              .map(ForumLikerModel.fromJson)
              .toList()
        : <ForumLikerModel>[];

    return ForumTopicModel(
      id: json['discussionId'] as String? ?? json['id'] as String? ?? '',
      authorId: authorId,
      title: json['title'] as String? ?? '',
      authorName: authorName,
      authorAvatar: isAnonymous ? '' : authorAvatar,
      category: json['category'] as String? ?? 'General',
      content: json['content'] as String? ?? '',
      upvotes:
          json['reactionCount'] as int? ??
          json['upvotes'] as int? ??
          json['likesCount'] as int? ??
          0,
      repliesCount:
          json['commentCount'] as int? ??
          json['repliesCount'] as int? ??
          json['commentsCount'] as int? ??
          0,
      timeAgo: formattedTime.isNotEmpty ? formattedTime : 'Just now',
      createdAt: parsedUtc?.toLocal(),
      isLiked:
          json['reactedByMe'] as bool? ?? json['isLiked'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isOwner: json['mine'] as bool? ?? json['isOwner'] as bool? ?? false,
      isAnonymous: isAnonymous,
      isBookmarked:
          json['isBookmarked'] as bool? ?? json['savedByMe'] as bool? ?? false,
      likers: parsedLikers,
      isRepostedByMe:
          json['repostedByMe'] as bool? ??
          json['isRepostedByMe'] as bool? ??
          false,
      repostedBy: json['repostedBy'] as String?,
      repostCaption: json['repostCaption'] as String?,
      reposterId: json['reposterId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussionId': id,
      'id': id,
      'authorId': isAnonymous ? null : authorId,
      'title': title,
      'authorName': isAnonymous ? 'Anonymous' : authorName,
      'authorAvatar': isAnonymous ? '' : authorAvatar,
      'category': category,
      'content': content,
      'upvotes': upvotes,
      'repliesCount': repliesCount,
      'timeAgo': timeAgo,
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
      'isLiked': isLiked,
      'isPinned': isPinned,
      'isOwner': isOwner,
      'isAnonymous': isAnonymous,
      'anonymous': isAnonymous,
      'isBookmarked': isBookmarked,
      'likers': likers.map((l) => l.toJson()).toList(),
      'repostedByMe': isRepostedByMe,
      'repostedBy': repostedBy,
      'repostCaption': repostCaption,
      'reposterId': reposterId,
    };
  }
}

class SkillTutorialModel {
  final String id;
  final String title;
  final String authorName;
  final String category;
  final String duration;
  final int xpReward;
  final int likesCount;
  final String coverUrl;

  SkillTutorialModel({
    required this.id,
    required this.title,
    required this.authorName,
    required this.category,
    required this.duration,
    this.xpReward = 25,
    this.likesCount = 0,
    required this.coverUrl,
  });
}

class CareerGoalModel {
  final String id;
  final String title;
  final String authorName;
  final double progress; // 0.0 to 1.0
  final int cheersCount;
  final String targetDate;

  CareerGoalModel({
    required this.id,
    required this.title,
    required this.authorName,
    required this.progress,
    this.cheersCount = 0,
    required this.targetDate,
  });
}

class FollowUserModel {
  final String userId;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String status;
  bool isFollowingBack;
  final DateTime? followedAt;

  FollowUserModel({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.status = 'ACCEPTED',
    this.isFollowingBack = false,
    this.followedAt,
  });

  factory FollowUserModel.fromJson(
    Map<String, dynamic> json, {
    bool isFollowingBack = false,
  }) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['author'] is Map<String, dynamic>
              ? json['author'] as Map<String, dynamic>
              : json);

    final uid =
        userMap['userId']?.toString() ??
        userMap['id']?.toString() ??
        userMap['followerId']?.toString() ??
        '';

    final name = (userMap['fullName'] as String?)?.isNotEmpty == true
        ? userMap['fullName'] as String
        : (userMap['name'] as String?)?.isNotEmpty == true
        ? userMap['name'] as String
        : (userMap['username'] as String?)?.isNotEmpty == true
        ? userMap['username'] as String
        : 'User';

    final username = (userMap['username'] as String?)?.isNotEmpty == true
        ? userMap['username'] as String
        : uid;

    final avatar =
        userMap['avatarUrl'] as String? ?? userMap['avatar'] as String?;

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (_) {}
    }

    return FollowUserModel(
      userId: uid,
      fullName: name,
      username: username,
      avatarUrl: avatar,
      status: json['status'] as String? ?? 'ACCEPTED',
      isFollowingBack: isFollowingBack,
      followedAt: createdAt,
    );
  }
}
