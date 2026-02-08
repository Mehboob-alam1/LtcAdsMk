/// A single activity event from Firebase (mining, boost, withdraw, etc.).
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.label,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String label;
  final int createdAt;

  factory ActivityItem.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return ActivityItem(
      id: id,
      type: (data['type'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
      createdAt: created is num ? created.toInt() : 0,
    );
  }
}
