enum QuizMatchStatus {
  waiting,
  inProgress,
  completed,
  abandoned,
  unknown,
}

QuizMatchStatus quizMatchStatusFromWire(String? value) {
  return switch ((value ?? '').trim().toUpperCase()) {
    'WAITING' => QuizMatchStatus.waiting,
    'IN_PROGRESS' => QuizMatchStatus.inProgress,
    'COMPLETED' => QuizMatchStatus.completed,
    'ABANDONED' => QuizMatchStatus.abandoned,
    _ => QuizMatchStatus.unknown,
  };
}

class QuizMatchPlayer {
  const QuizMatchPlayer({
    required this.id,
    required this.name,
    required this.score,
  });

  final String? id;
  final String? name;
  final int score;
}

class QuizMatchEvent {
  const QuizMatchEvent({
    required this.matchId,
    required this.quizId,
    required this.status,
    required this.player1,
    required this.player2,
    required this.winnerId,
  });

  final String matchId;
  final String quizId;
  final QuizMatchStatus status;
  final QuizMatchPlayer player1;
  final QuizMatchPlayer? player2;
  final String? winnerId;

  factory QuizMatchEvent.fromJson(Map<String, dynamic> json) {
    final player1Id = json['player1Id']?.toString();
    final player2Id = json['player2Id']?.toString();
    return QuizMatchEvent(
      matchId: (json['matchId'] ?? '').toString(),
      quizId: (json['quizId'] ?? '').toString(),
      status: quizMatchStatusFromWire(json['status']?.toString()),
      player1: QuizMatchPlayer(
        id: player1Id,
        name: json['player1Name']?.toString(),
        score: (json['player1Score'] as num?)?.toInt() ?? 0,
      ),
      player2: player2Id == null && json['player2Name'] == null
          ? null
          : QuizMatchPlayer(
              id: player2Id,
              name: json['player2Name']?.toString(),
              score: (json['player2Score'] as num?)?.toInt() ?? 0,
            ),
      winnerId: json['winnerId']?.toString(),
    );
  }

  QuizMatchPlayer? opponentFor(String? currentUserId) {
    if (currentUserId != null && currentUserId == player1.id) return player2;
    if (currentUserId != null && currentUserId == player2?.id) return player1;
    return player2 ?? player1;
  }

  String get eventKey =>
      '$matchId|${status.name}|${player1.score}|${player2?.score ?? 0}|$winnerId';
}
