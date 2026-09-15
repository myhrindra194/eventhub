// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModerationEntryDto _$ModerationEntryDtoFromJson(
  Map<String, dynamic> json,
) => ModerationEntryDto(
  id: json['id'] as String,
  targetType: json['target_type'] as String,
  targetId: json['target_id'] as String,
  reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
  lastReason: json['last_reason'] as String?,
  status: json['status'] as String?,
  autoHidden: json['auto_hidden'] as bool? ?? false,
  decision: json['decision'] as String?,
  decisionNote: json['decision_note'] as String?,
  decidedAt: const NullableTimestampConverter().fromJson(json['decided_at']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updated_at']),
);

ReportRecordDto _$ReportRecordDtoFromJson(Map<String, dynamic> json) =>
    ReportRecordDto(
      id: json['id'] as String,
      reason: json['reason'] as String?,
      details: json['details'] as String? ?? '',
      reporterId: json['reporter_id'] as String?,
      createdAt: const NullableTimestampConverter().fromJson(
        json['created_at'],
      ),
    );

ModerationDecisionDto _$ModerationDecisionDtoFromJson(
  Map<String, dynamic> json,
) => ModerationDecisionDto(
  action: json['action'] as String?,
  note: json['note'] as String? ?? '',
  decidedBy: json['decided_by'] as String?,
  decidedAt: const NullableTimestampConverter().fromJson(json['decided_at']),
);

ReportedAccountDto _$ReportedAccountDtoFromJson(Map<String, dynamic> json) =>
    ReportedAccountDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: const NullableTimestampConverter().fromJson(
        json['created_at'],
      ),
    );

AdminAccountDto _$AdminAccountDtoFromJson(Map<String, dynamic> json) =>
    AdminAccountDto(
      userId: json['user_id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      grantedBy: json['granted_by'] as String?,
      grantedAt: const NullableTimestampConverter().fromJson(
        json['granted_at'],
      ),
    );
