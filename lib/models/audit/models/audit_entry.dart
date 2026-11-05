import '../../../core/utils/json_value.dart';

/// Historial de comandos locales, no una auditoría de seguridad de servidor.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.at,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.detail,
  });
  final String id, actorId, actorName, action, detail;
  final DateTime at;
  Map<String, Object> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'actorId': actorId,
    'actorName': actorName,
    'action': action,
    'detail': detail,
  };
  factory AuditEntry.fromJson(JsonMap j) => AuditEntry(
    id: jsonText(j, 'id'),
    at: jsonDate(j, 'at'),
    actorId: jsonText(j, 'actorId'),
    actorName: jsonText(j, 'actorName'),
    action: jsonText(j, 'action'),
    detail: jsonText(j, 'detail'),
  );
}
