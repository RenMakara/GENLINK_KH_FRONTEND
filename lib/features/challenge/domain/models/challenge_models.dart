enum ChallengeStatus { notStarted, inProgress, completed, claimed, unknown }

ChallengeStatus challengeStatusFromWire(String? value) {
  return switch ((value ?? '').trim().toUpperCase()) {
    'NOT_STARTED' => ChallengeStatus.notStarted,
    'IN_PROGRESS' => ChallengeStatus.inProgress,
    'COMPLETED' => ChallengeStatus.completed,
    'CLAIMED' => ChallengeStatus.claimed,
    _ => ChallengeStatus.unknown,
  };
}

enum ChallengeType {
  habit,
  task,
  finance,
  quiz,
  event,
  community,
  focus,
  unknown,
}

ChallengeType challengeTypeFromWire(String? value) {
  return switch ((value ?? '').trim().toUpperCase()) {
    'HABIT' => ChallengeType.habit,
    'TASK' => ChallengeType.task,
    'FINANCE' => ChallengeType.finance,
    'QUIZ' => ChallengeType.quiz,
    'EVENT' => ChallengeType.event,
    'COMMUNITY' => ChallengeType.community,
    'FOCUS' => ChallengeType.focus,
    _ => ChallengeType.unknown,
  };
}

class ChallengeModel {
  const ChallengeModel({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.xpReward,
    required this.deadline,
    required this.status,
    required this.progress,
  });

  final String challengeId;
  final String title;
  final String description;
  final ChallengeType challengeType;
  final int xpReward;
  final DateTime? deadline;
  final ChallengeStatus status;
  final int progress;

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    final deadlineValue = json['deadline']?.toString();
    return ChallengeModel(
      challengeId: (json['challengeId'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      challengeType: challengeTypeFromWire(json['challengeType']?.toString()),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      deadline: deadlineValue == null ? null : DateTime.tryParse(deadlineValue),
      status: challengeStatusFromWire(json['status']?.toString()),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isJoined =>
      status == ChallengeStatus.inProgress ||
      status == ChallengeStatus.completed ||
      status == ChallengeStatus.claimed;

  bool get isCompleted =>
      status == ChallengeStatus.completed || status == ChallengeStatus.claimed;

  bool get isRewardClaimed => status == ChallengeStatus.claimed;

  ChallengeModel copyWith({
    String? challengeId,
    String? title,
    String? description,
    ChallengeType? challengeType,
    int? xpReward,
    DateTime? deadline,
    ChallengeStatus? status,
    int? progress,
  }) {
    return ChallengeModel(
      challengeId: challengeId ?? this.challengeId,
      title: title ?? this.title,
      description: description ?? this.description,
      challengeType: challengeType ?? this.challengeType,
      xpReward: xpReward ?? this.xpReward,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
