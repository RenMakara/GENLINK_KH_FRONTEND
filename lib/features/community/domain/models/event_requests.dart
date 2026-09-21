enum EventMode {
  online,
  inPerson,
  unknown;

  static EventMode fromString(String? val) {
    if (val == null) return EventMode.unknown;
    final normalized = val.trim().toUpperCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'ONLINE':
        return EventMode.online;
      case 'IN_PERSON':
      case 'INPERSON':
        return EventMode.inPerson;
      default:
        return EventMode.unknown;
    }
  }

  String get toBackendValue {
    switch (this) {
      case EventMode.online:
        return 'ONLINE';
      case EventMode.inPerson:
      case EventMode.unknown:
        return 'IN_PERSON';
    }
  }

  String get label {
    switch (this) {
      case EventMode.online:
        return 'Online';
      case EventMode.inPerson:
      case EventMode.unknown:
        return 'In person';
    }
  }
}

class EventCreateRequest {
  final String title;
  final String? description;
  final String? category;
  final String? coverImageUrl;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String mode;
  final String? meetingUrl;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? attendeeLimit;
  final String status;
  final String? language;
  final bool paid;
  final double? price;
  final String? currency;

  const EventCreateRequest({
    required this.title,
    this.description,
    this.category,
    this.coverImageUrl,
    required this.startDateTime,
    required this.endDateTime,
    this.mode = 'IN_PERSON',
    this.meetingUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.attendeeLimit,
    this.status = 'PUBLISHED',
    this.language,
    this.paid = false,
    this.price,
    this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'coverImageUrl': coverImageUrl,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'mode': mode,
      'meetingUrl': meetingUrl,
      'locationName': locationName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (attendeeLimit != null) 'attendeeLimit': attendeeLimit,
      'status': status,
      if (language != null) 'language': language,
      'paid': paid,
      'price': paid ? price : null,
      'currency': paid ? currency : null,
    };
  }

  factory EventCreateRequest.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic val) {
      if (val is DateTime) return val;
      if (val is String && val.trim().isNotEmpty) {
        return DateTime.tryParse(val.trim()) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val.trim());
      return null;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val.trim());
      return null;
    }

    return EventCreateRequest(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      startDateTime: parseDt(json['startDateTime']),
      endDateTime: parseDt(json['endDateTime']),
      mode: json['mode'] as String? ?? 'IN_PERSON',
      meetingUrl: json['meetingUrl'] as String?,
      locationName: json['locationName'] as String?,
      latitude: parseNum(json['latitude']),
      longitude: parseNum(json['longitude']),
      attendeeLimit: parseInt(json['attendeeLimit']),
      status: json['status'] as String? ?? 'PUBLISHED',
      language: json['language'] as String?,
      paid: json['paid'] as bool? ?? false,
      price: parseNum(json['price']),
      currency: json['currency'] as String?,
    );
  }
}

class EventRegistrationRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String university;
  final String faculty;
  final String studyYear;
  final bool termsAccepted;

  const EventRegistrationRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.university,
    required this.faculty,
    required this.studyYear,
    this.termsAccepted = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'university': university,
      'faculty': faculty,
      'studyYear': studyYear,
      'termsAccepted': termsAccepted,
    };
  }

  factory EventRegistrationRequest.fromJson(Map<String, dynamic> json) {
    return EventRegistrationRequest(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      university: json['university'] as String? ?? '',
      faculty: json['faculty'] as String? ?? '',
      studyYear: json['studyYear'] as String? ?? '',
      termsAccepted: json['termsAccepted'] as bool? ?? false,
    );
  }
}

class RsvpResponseModel {
  final String eventId;
  final String status;
  final int attendeeCount;
  final int xpAwarded;
  final double? amountPaid;
  final bool simulatedPayment;

  const RsvpResponseModel({
    required this.eventId,
    required this.status,
    required this.attendeeCount,
    required this.xpAwarded,
    this.amountPaid,
    required this.simulatedPayment,
  });

  factory RsvpResponseModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val.trim()) ?? 0;
      return 0;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val.trim());
      return null;
    }

    return RsvpResponseModel(
      eventId: json['eventId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'JOINED',
      attendeeCount: parseInt(json['attendeeCount']),
      xpAwarded: parseInt(json['xpAwarded']),
      amountPaid: parseDouble(json['amountPaid']),
      simulatedPayment: json['simulatedPayment'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'status': status,
      'attendeeCount': attendeeCount,
      'xpAwarded': xpAwarded,
      'amountPaid': amountPaid,
      'simulatedPayment': simulatedPayment,
    };
  }
}

class EventAttendeeModel {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? role;
  final DateTime? joinedAt;

  const EventAttendeeModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.role,
    this.joinedAt,
  });

  String get userId => id;

  factory EventAttendeeModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    final joinedAtStr = json['joinedAt'] as String?;
    return EventAttendeeModel(
      id: userObj['id']?.toString() ?? userObj['userId']?.toString() ?? '',
      fullName: userObj['fullName'] as String? ??
          userObj['username'] as String? ??
          'Attendee',
      username: userObj['username'] as String? ?? '',
      avatarUrl: userObj['avatarUrl'] as String?,
      role: json['role']?.toString(),
      joinedAt: joinedAtStr != null ? DateTime.tryParse(joinedAtStr) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joinedAt': joinedAt!.toIso8601String(),
    };
  }
}
