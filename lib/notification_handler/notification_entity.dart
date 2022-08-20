class NotificationEntity {
  final int? id;
  final String? title;
  final String? body;
  final Map<String, String>? payload;
  final List<DateTime>? schedules;

  const NotificationEntity({
    this.id,
    this.title,
    this.body,
    this.payload,
    this.schedules,
  });
}
