# GATO

Daily journal, notes, quotes and voice memos. Flutter + Supabase. Google sign-in only, optional 4-digit PIN lock, home-screen quick-action widget.

## Get the APK
1. Push this repo to GitHub (branch `main`).
2. The **Build APK** workflow runs on every push. Download `app-release.apk` from the run's artifacts or the repo's Releases.

## One-time Supabase setup (Google sign-in)
1. Google Cloud Console: create an OAuth client (type *Web*). Add the Supabase callback
   `https://juedaxrgpynmhdohuyxn.supabase.co/auth/v1/callback` as an authorized redirect URI.
2. Supabase Dashboard > Authentication > Providers > Google: enable it and paste the client ID and secret.
3. Supabase Dashboard > Authentication > URL Configuration > Redirect URLs: add `io.supabase.gato://login-callback/`.

The database tables and the `gato-voice` storage bucket are already created.

## Notes
- `android/` is generated in CI (`flutter create`) and patched by `tools/patch_android.py` (permissions, deep links, widget).
- `ci/debug.keystore` keeps every build signed with the same key so new APKs install over old ones.
- Supabase URL and publishable key are in `lib/config.dart` (publishable keys are safe in clients; data is protected by row level security).
