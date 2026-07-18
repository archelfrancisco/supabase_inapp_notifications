library supabase_inapp_notifications;

import 'package:supabase_flutter/supabase_flutter.dart';

/// A single in-app notification row.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? type;
  final Map<String, dynamic> raw;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.type,
    required this.raw,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        isRead: (m['is_read'] ?? false) as bool,
        type: m['type'] as String?,
        raw: m,
      );
}

/// Lightweight in-app notifications for Flutter + Supabase.
///
/// Sending goes through a `SECURITY DEFINER` Postgres function so clients can
/// deliver a notification to *another* user without needing write access to
/// that user's rows — the function is the only thing that inserts, keeping RLS
/// tight. Reading is plain RLS-checked SELECTs scoped to the signed-in user.
///
/// Expected schema:
/// ```sql
/// create table notifications (
///   id uuid primary key default gen_random_uuid(),
///   user_id uuid not null,
///   title text not null,
///   body text not null,
///   type text,
///   is_read boolean not null default false,
///   created_at timestamptz not null default now()
/// );
///
/// create function notify(p_user uuid, p_title text, p_body text)
///   returns void language sql security definer as $$
///   insert into notifications(user_id, title, body) values (p_user, p_title, p_body);
/// $$;
/// ```
class SupabaseNotifications {
  SupabaseNotifications(
    this._client, {
    this.table = 'notifications',
    this.sendRpc = 'notify',
  });

  final SupabaseClient _client;
  final String table;
  final String sendRpc;

  String? get _uid => _client.auth.currentUser?.id;

  /// Deliver a notification to [userId]. Swallows errors — delivery is
  /// non-critical and should never crash the calling flow.
  Future<void> notify(String userId, String title, String body) async {
    try {
      await _client.rpc(
        sendRpc,
        params: {'p_user': userId, 'p_title': title, 'p_body': body},
      );
    } catch (_) {
      /* non-critical */
    }
  }

  /// The signed-in user's most recent notifications (newest first).
  Future<List<AppNotification>> mine({int limit = 50}) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('user_id', _uid as Object)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((m) => AppNotification.fromMap((m as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Count of unread notifications, for a badge on a bell icon.
  Future<int> unreadCount() async {
    final rows = await _client
        .from(table)
        .select('id')
        .eq('user_id', _uid as Object)
        .eq('is_read', false);
    return (rows as List).length;
  }

  /// True if the user has an unread notification of [type] (e.g. `'update'`),
  /// handy for animating a bell only on a specific kind of notice.
  Future<bool> hasUnreadOfType(String type) async {
    try {
      final rows = await _client
          .from(table)
          .select('id')
          .eq('user_id', _uid as Object)
          .eq('is_read', false)
          .eq('type', type)
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Mark every notification for the signed-in user as read.
  Future<void> markAllRead() async {
    await _client
        .from(table)
        .update({'is_read': true})
        .eq('user_id', _uid as Object)
        .eq('is_read', false);
  }
}
