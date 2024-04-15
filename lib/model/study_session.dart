class StudySession {
  String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration plannedDuration;
  final Duration actualDuration;
  final String mode; // '定时模式' 或 '随时模式'
  final String summary; // 自习概要
  final int pauseCount;
  final List<Duration> pauseDurations;
  final double? rating;

  StudySession({
    this.id = '',
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    this.actualDuration = Duration.zero,
    this.mode = '随时模式',
    this.summary = '',
    this.pauseCount = 0,
    this.pauseDurations = const [],
    this.rating,
  });

  StudySession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    Duration? plannedDuration,
    Duration? actualDuration,
    String? mode,
    String? summary,
    int? pauseCount,
    List<Duration>? pauseDurations,
    double? rating,
  }) {
    return StudySession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      mode: mode ?? this.mode,
      summary: summary ?? this.summary,
      pauseCount: pauseCount ?? this.pauseCount,
      pauseDurations: pauseDurations ?? this.pauseDurations,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'plannedDuration': plannedDuration.inMinutes,
      'actualDuration': actualDuration.inMinutes,
      'mode': mode,
      'summary': summary,
      'pauseCount': pauseCount,
      'pauseDurations': pauseDurations.map((d) => d.inMinutes).toList(),
      'rating': rating,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map,String id) {
    List<Duration> pauseDurations = [];
    if (map['pauseDurations'] != null) {
      pauseDurations = (map['pauseDurations'] as List).map((d) => Duration(minutes: d)).toList();
    }

    return StudySession(
      id: id,
      startTime: (map['startTime'] ).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] ).toDate() : null,
      plannedDuration: Duration(minutes: map['plannedDuration']),
      actualDuration: Duration(minutes: map['actualDuration']),
      mode: map['mode'],
      summary: map['summary'] ?? '',
      pauseCount: map['pauseCount'] ?? 0,
      pauseDurations: pauseDurations,
      rating: map['rating'].toDouble(),
    );
  }
}
