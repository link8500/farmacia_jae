import '../../../core/utils/json_value.dart';

enum IncidentStatus { open, inProgress, resolved }

class SupportCase {
  const SupportCase({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.createdAt,
    this.status = IncidentStatus.open,
    this.resolvedAt,
    this.resolution = '',
  });
  final String id, title, description, priority, resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final IncidentStatus status;
  SupportCase update({
    required String title,
    required String description,
    required String priority,
    required IncidentStatus status,
    required String resolution,
    required DateTime now,
  }) => SupportCase(
    id: id,
    title: title,
    description: description,
    priority: priority,
    createdAt: createdAt,
    status: status,
    resolution: resolution,
    resolvedAt: status == IncidentStatus.resolved ? resolvedAt ?? now : null,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolution': resolution,
  };
  factory SupportCase.fromJson(JsonMap j) => SupportCase(
    id: jsonText(j, 'id'),
    title: jsonText(j, 'title'),
    description: jsonText(j, 'description'),
    priority: jsonText(j, 'priority'),
    createdAt: jsonDate(j, 'createdAt'),
    status: jsonEnum(j, 'status', IncidentStatus.values),
    resolvedAt: j['resolvedAt'] == null ? null : jsonDate(j, 'resolvedAt'),
    resolution: jsonText(j, 'resolution'),
  );
}
