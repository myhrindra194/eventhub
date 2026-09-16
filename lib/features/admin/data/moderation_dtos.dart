import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:json_annotation/json_annotation.dart';

part 'moderation_dtos.g.dart';

/// Documents du back-office de modération, tous lisibles par les seuls
/// administrateurs. Les colonnes de type énumération sont conservées en
/// texte : une valeur écrite par un build plus récent se dégrade en
/// « inconnu » au lieu de faire échouer toute une liste.

ReportReason? _reason(String? wire) {
  for (final reason in ReportReason.values) {
    if (reason.wire == wire) return reason;
  }
  return null;
}

/// `moderationQueue/{targetType}_{targetId}`. L’identifiant est celui du
/// document lui-même, qui est aussi celui vers lequel l’application route.
@JsonSerializable(createToJson: false)
class ModerationEntryDto {
  const ModerationEntryDto({
    required this.id,
    this.targetType = '',
    this.targetId = '',
    this.reportCount = 0,
    this.lastReason,
    this.status,
    this.decision,
    this.decisionNote,
    this.decidedAt,
    this.updatedAt,
  });

  factory ModerationEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationEntryDtoFromJson(json);

  factory ModerationEntryDto.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) => ModerationEntryDto.fromJson({...data, 'id': id});

  final String id;
  final String targetType;
  final String targetId;
  final int reportCount;
  final String? lastReason;
  final String? status;
  final String? decision;
  final String? decisionNote;
  @NullableTimestampConverter()
  final DateTime? decidedAt;
  @NullableTimestampConverter()
  final DateTime? updatedAt;

  /// `null` pour un type de cible que cette version de l’application ne sait
  /// pas afficher.
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
      decision: ModerationAction.fromWire(decision),
      decisionNote: decisionNote,
      decidedAt: decidedAt,
      updatedAt: updatedAt,
    );
  }
}

/// `reports/{id}`, tel qu’un modérateur le voit.
@JsonSerializable(createToJson: false)
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

  factory ReportRecordDto.fromFirestore(String id, Map<String, dynamic> data) =>
      ReportRecordDto.fromJson({...data, 'id': id});

  /// Longueur de [ReportRecord.reporterKey] : assez pour remarquer qu’un même
  /// compte signale beaucoup de choses, pas assez pour être une identité.
  static const reporterKeyLength = 8;

  final String id;
  final String? reason;
  final String details;

  /// `''` une fois le compte de l’auteur du signalement supprimé.
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

/// `moderationQueue/{entryId}/decisions/{id}` — historique en ajout seul.
@JsonSerializable(createToJson: false)
class ModerationDecisionDto {
  const ModerationDecisionDto({this.action, this.note = '', this.by, this.at});

  factory ModerationDecisionDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationDecisionDtoFromJson(json);

  final String? action;
  final String note;
  final String? by;
  @NullableTimestampConverter()
  final DateTime? at;

  ModerationDecision toDomain() => ModerationDecision(
    action: ModerationAction.fromWire(action),
    note: note,
    by: by ?? '',
    at: at,
  );
}

/// `users/{uid}` d’un compte signalé : les administrateurs peuvent lire
/// n’importe quel profil, et personne ne peut les lister.
@JsonSerializable(createToJson: false)
class ReportedAccountDto {
  const ReportedAccountDto({
    required this.id,
    this.name = '',
    this.email = '',
    this.role = '',
    this.suspended = false,
    this.createdAt,
  });

  factory ReportedAccountDto.fromJson(Map<String, dynamic> json) =>
      _$ReportedAccountDtoFromJson(json);

  factory ReportedAccountDto.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) => ReportedAccountDto.fromJson({...data, 'id': id});

  final String id;
  final String name;
  final String email;
  final String role;

  /// L’état lui-même, pas une déduction tirée de la dernière décision : la
  /// modération l’écrit sur le profil, et les règles le relisent à chaque
  /// écriture que le compte tente.
  final bool suspended;
  @NullableTimestampConverter()
  final DateTime? createdAt;

  ReportedAccount toDomain() => ReportedAccount(
    id: id,
    name: name,
    email: email,
    role: role,
    suspended: suspended,
    createdAt: createdAt,
  );
}

/// `admins/{uid}` — créé et supprimé depuis la seule console Firebase.
@JsonSerializable(createToJson: false)
class AdminAccountDto {
  const AdminAccountDto({
    required this.id,
    this.email,
    this.name,
    this.grantedAt,
  });

  factory AdminAccountDto.fromJson(Map<String, dynamic> json) =>
      _$AdminAccountDtoFromJson(json);

  factory AdminAccountDto.fromFirestore(String id, Map<String, dynamic> data) =>
      AdminAccountDto.fromJson({...data, 'id': id});

  final String id;
  final String? email;
  final String? name;
  @NullableTimestampConverter()
  final DateTime? grantedAt;

  AdminAccount toDomain() => AdminAccount(
    id: id,
    email: email ?? '',
    name: name,
    grantedAt: grantedAt,
  );
}
