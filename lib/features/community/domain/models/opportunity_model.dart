class OpportunityModel {
  final String id;
  final String title;
  final String organization;
  final String type;
  final String description;
  final DateTime? deadline;
  final String location;
  final String applyLink;
  final bool savedByMe;
  final bool expired;
  final DateTime? createdAt;

  const OpportunityModel({
    required this.id,
    required this.title,
    this.organization = '',
    this.type = 'JOB',
    this.description = '',
    this.deadline,
    this.location = '',
    this.applyLink = '',
    this.savedByMe = false,
    this.expired = false,
    this.createdAt,
  });

  bool get isExpired {
    if (expired) return true;
    if (deadline == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return target.isBefore(today);
  }

  int? get daysLeft {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return target.difference(today).inDays;
  }

  bool get isExpiringSoon {
    if (isExpired) return false;
    final days = daysLeft;
    return days != null && days >= 0 && days <= 3;
  }

  String get displayType {
    if (type.isEmpty) return 'Opportunity';
    final upper = type.toUpperCase();
    switch (upper) {
      case 'INTERNSHIP':
        return 'Internship';
      case 'SCHOLARSHIP':
        return 'Scholarship';
      case 'JOB':
      case 'FULL_TIME':
      case 'FULL-TIME':
        return 'Job';
      case 'PART_TIME':
      case 'PART-TIME':
        return 'Part-Time';
      case 'HACKATHON':
        return 'Hackathon';
      case 'VOLUNTEER':
        return 'Volunteer';
      default:
        return type[0].toUpperCase() + type.substring(1).toLowerCase();
    }
  }

  String get formattedDeadline {
    if (deadline == null) return 'Open-ended';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[deadline!.month - 1];
    return '$m ${deadline!.day}, ${deadline!.year}';
  }

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return OpportunityModel(
      id: (json['opportunityId'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      organization: (json['organization'] ?? '').toString(),
      type: (json['type'] ?? 'JOB').toString(),
      description: (json['description'] ?? '').toString(),
      deadline: parseDate(json['deadline']),
      location: (json['location'] ?? '').toString(),
      applyLink: (json['applyLink'] ?? '').toString(),
      savedByMe: json['savedByMe'] == true,
      expired: json['expired'] == true,
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunityId': id,
      'title': title,
      'organization': organization,
      'type': type,
      'description': description,
      'deadline': deadline != null
          ? '${deadline!.year.toString().padLeft(4, '0')}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}'
          : null,
      'location': location,
      'applyLink': applyLink,
      'savedByMe': savedByMe,
      'expired': expired,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  OpportunityModel copyWith({
    String? id,
    String? title,
    String? organization,
    String? type,
    String? description,
    DateTime? deadline,
    String? location,
    String? applyLink,
    bool? savedByMe,
    bool? expired,
    DateTime? createdAt,
  }) {
    return OpportunityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      type: type ?? this.type,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      location: location ?? this.location,
      applyLink: applyLink ?? this.applyLink,
      savedByMe: savedByMe ?? this.savedByMe,
      expired: expired ?? this.expired,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
