# Personal sync setup — iOS + Android

The optional account flow never blocks local tasks or onboarding. Both native clients use the same authenticated `sync_personal` RPC. It compares mutation timestamps, includes deletion tombstones, and commits atomically under owner-only RLS. Sync is manual; realtime and team sharing remain outside C1.

## Existing project

- Open your configured project in the [Supabase dashboard](https://supabase.com/dashboard). The owner's environment identifier and URL are kept in local configuration.
- Initial schema and privileges were already deployed. Do not rerun `schema.sql` on this project.
- Migration `20261007230659_personal_sync_rpc` deployed on 2026-10-08 (Cairo time).
- Security advisor returned no findings after deployment.
- Rollback-only fixtures verified stale-write protection, date-only transport, new/known tombstones, project detachment, atomic failure and account isolation. No test account, email or data persisted.

## Local client configuration

Only public client credentials belong in applications. Never use `service_role`, a secret key or a database password.

### iOS

Copy `ios/TaskManagement/Resources/SupabaseConfig.example.plist` to `SupabaseConfig.plist` in the same folder and set the project URL and public client key. The file is ignored by Git and is already referenced by the checked-in Xcode project. When regenerating with XcodeGen, keep the real file local before generation.

### Android

Copy `android/supabase.example.properties` to `android/supabase.properties`, set the URL and public client key, then rebuild. The real file is ignored by Git. Without configuration, local tasks still work and the account sheet explains that sync is unavailable in that build.

## New backend only

Run `docs/supabase/schema.sql` once on a new project, then `supabase/migrations/20261007230659_personal_sync_rpc.sql`. Enable email/password auth with email confirmation. Existing projects should apply the migration only after verifying their schema matches this repository.

## Device acceptance

Open the optional account screen, register using your own email, confirm the email, and sign in. Sync one device, then the second device under the same account. Verify edit/delete propagation and offline failure without local data loss. This real-account, two-device path remains pending; SQL verification is not a substitute.

Before the first sync, each client saves an atomic JSON snapshot under its app-private Application Support/files `Backups` directory. A failed backup stops sync. The local data set binds to the first synced account; another account cannot upload it. Signing out retains local data. No account-switch/reset UI or export button is claimed.

Android session tokens are encrypted with Android Keystore in no-backup storage. iOS uses the Supabase SDK's Keychain storage. Credentials are never logged. Android reconciles reminders after a successful merge; iOS repository observation does the same.
