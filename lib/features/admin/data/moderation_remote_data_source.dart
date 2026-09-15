import 'dart:async';

import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/admin/data/moderation_dtos.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads of the moderation area and the two admin database functions.
///
/// Only `moderation_queue` is published to Realtime. Reports, decisions and
/// profiles are not — reports and profiles are private data that should not
/// travel on a broadcast channel — but every change to them also touches the
/// queue entry of their target (a report bumps `report_count`, a decision
/// stamps `decided_at`, a suspension is a decision). So those lists are
/// fetched again each time the entry changes, and stay live without their
/// own subscription.
class ModerationRemoteDataSource {
  ModerationRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// `administrators` changes only through [setAdminRole]: a local signal is
  /// enough to refresh the list after it.
  final _adminsChanged = StreamController<void>.broadcast();

  static const pageSize = 100;
  static const decisionsPageSize = 50;

  void dispose() => unawaited(_adminsChanged.close());

  Stream<List<ModerationEntry>> watchQueue({required bool open}) {
    final base = _client
        .from(Tables.moderationQueue)
        .stream(primaryKey: ['target_type', 'target_id']);
    final query = open
        // Most reported first; ties broken by recency below — Realtime
        // orders by one column only.
        ? base.eq('status', 'open').order('report_count')
        : base
              .inFilter('status', const ['resolved', 'dismissed'])
              .order('updated_at');
    return query
        .limit(pageSize)
        .map((rows) {
          final entries = [for (final row in rows) ?entryFromRow(row)];
          if (open) entries.sort(_mostReportedThenRecent);
          return entries;
        })
        .resilient(open ? 'moderation-queue-open' : 'moderation-queue-closed');
  }

  static int _mostReportedThenRecent(ModerationEntry a, ModerationEntry b) {
    final byCount = b.reportCount.compareTo(a.reportCount);
    if (byCount != 0) return byCount;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return (b.updatedAt ?? epoch).compareTo(a.updatedAt ?? epoch);
  }

  Stream<ModerationEntry?> watchEntry(String entryId) => _client
      .from(Tables.moderationQueue)
      .stream(primaryKey: ['target_type', 'target_id'])
      .eq('id', entryId)
      .map((rows) => rows.isEmpty ? null : entryFromRow(rows.first))
      .resilient('moderation-entry');

  /// Re-runs [fetch] on subscription and whenever the entry of
  /// [target]/[targetId] changes; an in-flight fetch made stale by a newer
  /// change is dropped.
  Stream<T> _refetchOnEntryChange<T>(
    ReportTarget target,
    String targetId,
    Future<T> Function() fetch,
  ) => watchEntry(ModerationEntry.composeId(target, targetId))
      .distinct(
        (a, b) =>
            a?.reportCount == b?.reportCount &&
            a?.status == b?.status &&
            a?.decidedAt == b?.decidedAt &&
            a?.updatedAt == b?.updatedAt,
      )
      .switchMap((_) => Stream.fromFuture(fetch()));

  Stream<List<ReportRecord>> watchReports({
    required ReportTarget target,
    required String targetId,
  }) => _refetchOnEntryChange(target, targetId, () async {
    final rows = await _client
        .from(Tables.reports)
        .select()
        .eq('target_type', target.name)
        .eq('target_id', targetId)
        .order('created_at')
        .limit(pageSize);
    return [for (final row in rows) reportFromRow(row)];
  });

  Stream<List<ModerationDecision>> watchDecisions(String entryId) {
    final parsed = ModerationEntry.parseId(entryId);
    if (parsed == null) return Stream.value(const []);
    final (target, targetId) = parsed;
    return _refetchOnEntryChange(target, targetId, () async {
      final rows = await _client
          .from(Tables.moderationDecisions)
          .select()
          .eq('target_type', target.name)
          .eq('target_id', targetId)
          .order('decided_at')
          .limit(decisionsPageSize);
      return [
        for (final row in rows) ModerationDecisionDto.fromJson(row).toDomain(),
      ];
    });
  }

  Stream<ReportedAccount?> watchAccount(String userId) =>
      _refetchOnEntryChange(ReportTarget.user, userId, () async {
        final row = await _client
            .from(Tables.profiles)
            .select('id, name, email, role, created_at')
            .eq('id', userId)
            .maybeSingle();
        return row == null ? null : ReportedAccountDto.fromJson(row).toDomain();
      });

  Stream<List<AdminAccount>> watchAdmins() => _adminsChanged.stream
      .startWith(null)
      .switchMap((_) => Stream.fromFuture(_fetchAdmins()));

  Future<List<AdminAccount>> _fetchAdmins() async {
    final rows = await _client
        .from(Tables.administrators)
        .select()
        .order('granted_at', ascending: true)
        .limit(pageSize);
    return [for (final row in rows) AdminAccountDto.fromJson(row).toDomain()];
  }

  /// `moderate_content` returns `{ok, cancelled_reservations?}`; the count
  /// is present for an event removal only.
  Future<int?> moderate({
    required String targetType,
    required String targetId,
    required String action,
    required String note,
  }) async {
    final result = await _client.rpc<dynamic>(
      Rpc.moderateContent,
      params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_action': action,
        'p_note': note,
      },
    );
    return switch (result) {
      {'cancelled_reservations': final num count} => count.toInt(),
      _ => null,
    };
  }

  Future<void> setAdminRole({
    required String email,
    required bool admin,
  }) async {
    await _client.rpc<dynamic>(
      Rpc.setAdminRole,
      params: {'p_email': email, 'p_admin': admin},
    );
    _adminsChanged.add(null);
  }

  static ModerationEntry? entryFromRow(Map<String, dynamic> row) =>
      ModerationEntryDto.fromJson(row).toDomain();

  static ReportRecord reportFromRow(Map<String, dynamic> row) =>
      ReportRecordDto.fromJson(row).toDomain();
}
