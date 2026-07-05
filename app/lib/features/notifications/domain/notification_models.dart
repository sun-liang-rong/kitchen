class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    this.relatedId,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String content;
  final String? relatedId;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      content: content,
      relatedId: relatedId,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
