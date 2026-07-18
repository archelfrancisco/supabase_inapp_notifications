# supabase_inapp_notifications

**Simple, secure in-app notifications for Flutter + Supabase.**

Deliver a notification to *any* user without loosening RLS, count unread for a
badge, and mark them read — a few lines instead of rolling your own each time.

## Why an RPC to send?

A client shouldn't have write access to other users' rows. So sending goes
through a `SECURITY DEFINER` Postgres function (`notify`) that is the *only*
thing allowed to insert. Reading stays plain RLS-checked SELECTs scoped to the
signed-in user. Tight by default.

## Usage

```dart
final notifs = SupabaseNotifications(Supabase.instance.client);

// Send to another user (e.g. "You were hired!")
await notifs.notify(otherUserId, 'You were hired! 🔧', 'Details inside.');

// Badge on a bell icon
final count = await notifs.unreadCount();

// Bell animation only for app-update notices
final hasUpdate = await notifs.hasUnreadOfType('update');

// Inbox
final items = await notifs.mine();

await notifs.markAllRead();
```

## Install

```yaml
dependencies:
  supabase_inapp_notifications: ^0.1.0
```

## Schema

```sql
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  title text not null,
  body text not null,
  type text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create function notify(p_user uuid, p_title text, p_body text)
  returns void language sql security definer as $$
  insert into notifications(user_id, title, body) values (p_user, p_title, p_body);
$$;
```

## License

MIT © 2026 Francisco Archel. Extracted from a production Flutter marketplace app.
