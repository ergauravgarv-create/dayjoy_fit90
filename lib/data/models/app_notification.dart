/// An in-app notification. Mirrors `participants/{uid}/notifications/{id}`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'general',
    this.read = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type; // dayComplete, badge, reminder, weeklyReport, motivation…
  final bool read;
  final DateTime createdAt;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(String id, Map<String, dynamic> j) =>
      AppNotification(
        id: id,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        type: (j['data']?['type'] as String?) ?? j['type'] as String? ?? 'general',
        read: j['read'] == true,
        createdAt: j['createdAt'] is String
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );
}
