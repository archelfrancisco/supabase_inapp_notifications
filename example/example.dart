import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_inapp_notifications/supabase_inapp_notifications.dart';

/// Assumes Supabase.initialize(...) was already called in main() with YOUR OWN
/// url + anonKey — never hard-code those in a shared repo.
Future<void> demo() async {
  final notifs = SupabaseNotifications(Supabase.instance.client);

  // Deliver to another user.
  await notifs.notify(
    'other-user-uuid',
    'You were hired! 🔧',
    'A client hired you for "Weld a gate".',
  );

  // Badge count for a bell icon.
  final unread = await notifs.unreadCount();
  print('Unread: $unread');

  // Full inbox, newest first.
  for (final n in await notifs.mine()) {
    print('${n.isRead ? "•" : "‣"} ${n.title} — ${n.body}');
  }

  await notifs.markAllRead();
}
