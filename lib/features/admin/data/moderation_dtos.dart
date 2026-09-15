import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:json_annotation/json_annotation.dart';

part 'moderation_dtos.g.dart';

/// Rows of the moderation back-office, all readable by administrators only
/// (RLS). Enum columns are kept as text: a value added to a Postgres enum
/// before the app knows it degrades to "unknown" instead of failing a list.

ReportReason? _reason(String? wire) {
  for (final reason in ReportReason.values) {
    if (reason.wire == wire) return reason;
  }
  return null;
}

/// `public.moderation_queue`. [id] is `<target_type>_<target_id>`, stamped
/// by a trigger: the id the app routes to.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ModerationEntryDto {
  const ModerationEntryDto({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.reportCount = 0,
    this.lastReason,
    this.status,
    this.autoHidden = false,
    this.decision,
    this.decisionNote,
    this.decidedAt,
    this.updatedAt,
  });

  factory ModerationEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationEntryDtoFromJson(json);

  final String id;
  final String targetType;
  final String targetId;
  final int reportCount;
  final String? lastReason;
  final String? status;
  final bool autoHidden;
  final String? decision;
  final String? decisionNote;
  @NullableTimestampConverter()
  final DateTime? decidedAt;
  @NullableTimestampConverter()
  final DateTime? updatedAt;

  /// `null` for a target type this version of the app cannot display.
  ModerationEntry? toDomain() {
    final target = ReportTarget.values.asNameMap()[targetType];
    if (target == null) return null;
    return ModerationEntry(
      id: id,
      target: target,
      targetId: targetId,
      reportCount: reportCount,
      status: ModerationStatus.fromWire(status),
      lastReason: _reason(lastReason),
      autoHidden: autoHidden,
      decision: ModerationAction.fromWire(decision),
      decisionNote: decisionNote,
      decidedAt: decidedAt,
      updatedAt: updatedAt,
    );
  }
}

/// `public.reports`, as a moderator sees it.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ReportRecordDto {
  const ReportRecordDto({
    required this.id,
    this.reason,
    this.details = '',
    this.reporterId,
    this.createdAt,
  });

  factory ReportRecordDto.fromJson(Map<String, dynamic> json) =>
      _$ReportRecordDtoFromJson(json);

  /// Length of [ReportRecord.reporterKey]: the first group of the uuid —
  /// enough to notice one account reporting many things, not an identity.
  static const reporterKeyLength = 8;

  final String id;
  final String? reason;
  final String details;

  /// Null once the reporter's account is deleted.
  final String? reporterId;
  @NullableTimestampConverter()
  final DateTime? createdAt;

  ReportRecord toDomain() {
    final reporter = reporterId ?? '';
    return ReportRecord(
      id: id,
      reason: _reason(reason),
      details: details,
      createdAt: createdAt,
      reporterKey: reporter.length > reporterKeyLength
          ? reporter.substring(0, reporterKeyLength)
          : reporter,
    );
  }
}

/// `public.moderation_decisions` (append-only history).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ModerationDecisionDto {
  const ModerationDecisionDto({
    this.action,
    this.note = '',
    this.decidedBy,
    this.decidedAt,
  });

  factory ModerationDecisionDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationDecisionDtoFromJson(json);

  final String? action;
  final String note;
  final String? decidedBy;
  @NullableTimestampConverter()
  final DateTime? decidedAt;

  ModerationDecision toDomain() => ModerationDecision(
    action: ModerationAction.fromWire(action),
    note: note,
    by: decidedBy ?? '',
    at: decidedAt,
  );
}

/// `public.profiles` of a reported account (administrators may read any).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ReportedAccountDto {
  const ReportedAccountDto({
    required this.id,
    this.name = '',
    this.email = '',
    this.role = '',
    this.createdAt,
  });

  factory ReportedAccountDto.fromJson(Map<String, dynamic> json) =>
      _$ReportedAccountDtoFromJson(json);

  final String id;
  final String name;
  final String email;
  final String role;
  @NullableTimestampConverter()
  final DateTime? createdAt;

  ReportedAccount toDomain() => ReportedAccount(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: createdAt,
  );
}

/// `public.administrators`, written only by `set_admin_role`.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class AdminAccountDto {
  const AdminAccountDto({
    required this.userId,
    this.email,
    this.name,
    this.grantedBy,
    this.grantedAt,
  });

  factory AdminAccountDto.fromJson(Map<String, dynamic> json) =>
      _$AdminAccountDtoFromJson(json);

  final String userId;
  final String? email;
  final String? name;
  final String? grantedBy;
  @NullableTimestampConverter()
  final DateTime? grantedAt;

  AdminAccount toDomain() => AdminAccount(
    id: userId,
    email: email ?? '',
    name: name,
    grantedBy: grantedBy,
    grantedAt: grantedAt,
  );
}
