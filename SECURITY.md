# Security and local configuration

Mahami has separate native iOS and Android clients. Local task storage works without a cloud account. Personal cloud sync is optional and uses authenticated, owner-only database policies.

## Keep local files outside Git

- iOS client configuration: copy `ios/TaskManagement/Resources/SupabaseConfig.example.plist` to `SupabaseConfig.plist` in the same directory.
- Android client configuration: copy `android/supabase.example.properties` to `android/supabase.properties`.
- Machine SDK/cache paths: use environment variables or ignored `android/local.properties`. The device launcher accepts `sdk.dir` and optional `taskmanagement.gradleUserHome` there; environment variables take precedence.
- Keep `.env` files, private signing keys/certificates, keystores, service-account credentials, session exports, databases and task backups local. Relevant ignore rules are included. Portable example configurations remain tracked.

Do not force-add ignored configuration or attach real account/session/data exports to public issues or releases. App screenshots in this repository were supplied by the owner and use fictional presentation content.

## Client keys and privileged secrets

Only a Supabase **publishable** key or supported legacy **anon** client key belongs in a mobile application. A shipped app's client key can be extracted from its binary. Database grants, Row Level Security and the authenticated user's identity control data access; hiding the client key is not a substitute for those controls. See [Supabase API key documentation](https://supabase.com/docs/guides/getting-started/api-keys).

Never put a `service_role` key, `sb_secret_` key, database password, JWT signing secret or administrator token in either client, its build configuration, screenshots or documentation.

## Public repository review

On October 8, 2026, the review covered all 19 reachable baseline commits, 322 unique Git blobs, commit messages and sensitive file names. No credential-pattern findings or tracked private signing/configuration files were identified. The actual local client configuration files and Android SDK configuration had never been tracked. [Review scope and evidence](docs/project/PUBLIC_REPO_REVIEW_2026-10-08.md).

GitHub secret scanning and push protection were enabled and verified through the repository API. These cover supported patterns; they do not detect every possible secret. The live Supabase security advisor returned no findings at the review time.

Ignore rules affect future additions. They do not remove committed history or invalidate an exposed credential. A confirmed leak requires revoking/rotating the affected secret and reviewing its historical exposure; deleting the current file alone is insufficient. Current documentation omits private workstation paths and deployment identifiers, while older commits retain non-secret operational metadata. No history rewrite was performed.
