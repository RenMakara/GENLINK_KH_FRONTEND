/// Event mode values accepted by the community API.
enum EventMode {
  online,
  inPerson;

  static EventMode fromString(String? value) {
    final normalized = (value ?? '').trim().toLowerCase().replaceAll('-', '_');
    if (normalized == 'online') return EventMode.online;
    return EventMode.inPerson;
  }

  String get apiValue => this == EventMode.online ? 'ONLINE' : 'IN_PERSON';
}

/// The attendee details collected by the event registration form.
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
    required this.termsAccepted,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'university': university,
        'faculty': faculty,
        'studyYear': studyYear,
        'termsAccepted': termsAccepted,
      };

  factory EventRegistrationRequest.fromJson(Map<String, dynamic> json) {
    return EventRegistrationRequest(
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      university: json['university']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      studyYear: json['studyYear']?.toString() ?? '',
      termsAccepted: json['termsAccepted'] == true,
    );
  }
}

/// Result returned after an event RSVP is created or restored.
class RsvpResponseModel {
  final String eventId;
  final String status;
  final int? attendeeCount;
  final int? xpAwarded;
  final double? amountPaid;
  final bool simulatedPayment;

  const RsvpResponseModel({
    required this.eventId,
    required this.status,
    this.attendeeCount,
    this.xpAwarded,
    this.amountPaid,
    this.simulatedPayment = false,
  });

  factory RsvpResponseModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amountPaid'];
    return RsvpResponseModel(
      eventId: json['eventId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'JOINED',
      attendeeCount: (json['attendeeCount'] as num?)?.toInt(),
      xpAwarded: (json['xpAwarded'] as num?)?.toInt(),
      amountPaid: amount is num ? amount.toDouble() : double.tryParse('$amount'),
      simulatedPayment: json['simulatedPayment'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'status': status,
        'attendeeCount': attendeeCount,
        'xpAwarded': xpAwarded,
        'amountPaid': amountPaid,
        'simulatedPayment': simulatedPayment,
      };
}
