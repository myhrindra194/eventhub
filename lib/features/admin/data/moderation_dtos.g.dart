// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModerationEntryDto _$ModerationEntryDtoFromJson(Map<String, dynamic> json) =>
    ModerationEntryDto(
      id: json['id'] as String,
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
      lastReason: json['lastReason'] as String?,
      status: json['status'] as String?,
      decision: json['decision'] as String?,
      decisionNote: json['decisionNote'] as String?,
      decidedAt: const NullableTimestampConverter().fromJson(json['decidedAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

ReportRecordDto _$ReportRecordDtoFromJson(Map<String, dynamic> json) =>
    ReportRecordDto(
      id: json['id'] as String,
      reason: json['reason'] as String?,
      details: json['details'] as String? ?? '',
      reporterId: json['reporterId'] as String?,
      createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
    );

ModerationDecisionDto _$ModerationDecisionDtoFromJson(
  Map<String, dynamic> json,
) => ModerationDecisionDto(
  action: json['action'] as String?,
  note: json['note'] as String? ?? '',
  by: json['by'] as String?,
  at: const NullableTimestampConverter().fromJson(json['at']),
);

ReportedAccountDto _$ReportedAccountDtoFromJson(Map<String, dynamic> json) =>
    ReportedAccountDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      suspended: json['suspended'] as bool? ?? false,
      createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
    );

AdminAccountDto _$AdminAccountDtoFromJson(Map<String, dynamic> json) =>
    AdminAccountDto(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      grantedAt: const NullableTimestampConverter().fromJson(json['grantedAt']),
    );
