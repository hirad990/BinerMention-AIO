# BinerMention PHP API

PHP 8.1+ and PDO MySQL are required. This is a substantial initial REST API implementation, but it must be configured and tested on the target cPanel account before production use.

## Deploy

1. Back up the target folder before replacing any files.
2. Upload the **contents** of this folder to the document root mapped to `https://binercraft.ir/mention-api-pub/`.
3. Create a MariaDB database and a dedicated database user in cPanel; grant that user access to the new database.
4. Import `schema.sql` once using phpMyAdmin. If the database already contains these tables, inspect them first rather than blindly importing the schema.
5. Copy `config.example.php` to `config.local.php` in the same folder. Edit `config.local.php` with the exact database name, username and password supplied by cPanel. Do not edit config.example.php with secrets. The local config is excluded from git and blocked by .htaccess.
6. Ensure `uploads/` is writable by PHP (normally 750 or the hosting provider's recommended permission). Do not use 777. The upload directory blocks PHP/script execution.
7. In cPanel PHP Selector, enable `pdo_mysql`, `fileinfo`, and `mbstring`; ensure `file_uploads=On`, `upload_max_filesize` and `post_max_size` are large enough for the configured 25 MB limit.
8. Open `https://binercraft.ir/mention-api-pub/`. It should return JSON with `status: ready` and `database: connected`. A 503 means the configuration or database is not ready.
9. Keep backups and test using a non-production account before connecting the Android app.

## Security and configuration

- Never commit `config.local.php`, database credentials, uploaded media or logs.
- Set `allowed_origins` in `config.local.php` to the exact web origin(s) once the web app exists. Android native requests do not normally send browser CORS origins.
- Use HTTPS. Access tokens are random bearer tokens; only their SHA-256 hashes are stored in the sessions table. Passwords use PHP `password_hash`.
- Rate limits are stored in MariaDB. Tune limits to the server and add scheduled cleanup for expired sessions and old rate-limit rows.
- Media accepts JPEG, PNG, WEBP, GIF, MP4 and WEBM, up to the configured limit. Hosting PHP limits must also permit the upload.
- For production, add monitoring, email verification, password reset, abuse reporting/moderation, account deletion/export, privacy review and more exhaustive security tests.

## Implemented endpoints

All paths below are relative to the API root. Protected routes require `Authorization: Bearer <token>`.

- `GET /`, `GET /health`, `GET /v1/health` — API/database health
- `POST /v1/auth/register` — username, email, password, optional display_name
- `POST /v1/auth/login` — identity (username or email) and password
- `POST /v1/auth/logout`, `GET /v1/auth/sessions`, `DELETE /v1/auth/sessions/{id}`
- `GET /v1/me`, `PATCH /v1/me`
- `GET /v1/users/{username}`, `GET /v1/users/{id}/posts`, `GET /v1/users/{id}/followers`, `GET /v1/users/{id}/following`, `GET /v1/users/{id}/followers`, `GET /v1/users/{id}/following`
- `GET /v1/search/posts?q=hashtag` — search posts containing a hashtag
- `GET /v1/posts`, `POST /v1/posts`, `GET /v1/posts/{id}`, `PATCH /v1/posts/{id}`, `DELETE /v1/posts/{id}`
- `POST /v1/posts/{id}/like`, `DELETE /v1/posts/{id}/like`
- `POST /v1/posts/{id}/repost`, `DELETE /v1/posts/{id}/repost`
- `POST /v1/users/{id}/follow`, `DELETE /v1/users/{id}/follow`
- `POST /v1/media` (multipart form field named `file`), `DELETE /v1/media/{id}`
- `GET /v1/notifications`, `POST /v1/notifications/{id}/read`, `POST /v1/notifications/read-all`
- `GET /v1/conversations`, `POST /v1/conversations` with `user_id`
- `GET /v1/conversations/{id}/messages`, `POST /v1/conversations/{id}/messages`, `POST /v1/conversations/{id}/read`

## Profile, comments, BinerAI, Insights and group rooms (2026-11-03)

The Android profile page requests the public profile and the user's posts separately. The API now implements `GET /v1/users/{id}/posts`; this route was missing in the earlier API even though it was listed above, which caused the profile screen to show `Endpoint not found`.

The main timeline now returns only top-level posts. Replies/comments remain attached to their parent and are fetched through:
- `GET /v1/posts/{id}/comments`
- `POST /v1/posts/{id}/comments` with `body` and optional owned `media_id`

New endpoints:
- `GET /v1/insights` — account totals and top posts, with a note explaining that historical views/reading time are only available after event tracking is enabled.
- `POST /v1/analytics/events` — authenticated post-view / dwell event recording.
- `POST /v1/ai/ask` — database-grounded BinerAI research for public BinerMention profiles and public posts.
- `GET /v1/groups`, `POST /v1/groups` — list/create group rooms.
- `POST /v1/groups/join` — join with the 16-character invite code.
- `GET /v1/groups/{id}/messages`, `POST /v1/groups/{id}/messages` — group chat history and message sending.

Group invite links use the `bm:` scheme, for example `bm:0123456789abcdef`. The invite code is generated with 64 bits of cryptographic randomness. Group membership is checked on every group message request. BinerMention currently supports group rooms, not broadcast channels.

### Apply the additive migration

Back up the MariaDB database, then run `migrations/2026_11_03_ai_groups_insights.sql` once in phpMyAdmin. This creates only the new group and analytics tables; it does not drop or recreate existing data. Deploy the updated contents of `PHP-API/` to the cPanel API directory after the backup.

### Insights event semantics

The Flutter feed records a `post_view` after a post is substantially visible and records `post_dwell` when it leaves the visible feed area. The API ignores a user's views of their own posts. The `views` value is a count of recorded view events, not a count of unique verified people; repeated sessions can create additional events. Reading time is a sum of client-reported visible dwell intervals and should be treated as an engagement estimate, not proof that a person read every word.

Fresh installations should import the complete `schema.sql`, which now includes the Insights and group-room tables. Existing installations should apply the additive migration above instead of re-importing the full schema.

### Configure the real BinerAI language model

BinerAI now uses an actual OpenAI-compatible chat-completions model. The PHP API retrieves public posts and public profile data, plus metadata for groups the signed-in user belongs to, then sends that bounded context to the configured model. Private group messages and private conversations are never included. If the provider is not configured or unavailable, the API returns an explicit error instead of generating a rule-based fake answer.

Add these values to the server-only `config.local.php` (never commit the API key):

```php
'ai_api_url' => 'https://api.groq.com/openai/v1/chat/completions',
'ai_api_key' => 'YOUR_PROVIDER_SECRET_KEY',
'ai_model' => 'YOUR_PROVIDER_MODEL_ID',
'ai_timeout_seconds' => 24,
```

Use a lightweight chat model supported by your provider. The endpoint and model are configurable, so another OpenAI-compatible provider can be used without changing the Flutter app. Enable PHP cURL on cPanel. The Android client checks `GET /v1/ai/status` and displays whether the model is configured. Keep the key only on the server; never add it to Flutter, web JavaScript, GitHub Actions artifacts or public repository files.

### BinerAI scope and verification

This first BinerAI API iteration retrieves and summarizes records already available inside BinerMention. It does **not** browse the public web or independently verify a real-world political identity. A platform BlueTick is only the platform's own verification state; it must never be presented as proof of a person's real-world identity or public office. A future external research/LLM provider must be configured server-side with a secret key, source citations, rate limits and clear provenance before BinerAI can make web-wide claims.

## Register example

```http
POST /v1/auth/register
Content-Type: application/json

{"username":"test_user","email":"test@example.com","password":"use-a-long-unique-password","display_name":"Test User"}
```

The API is not considered production-ready until schema import, DB credentials, PHP extensions, file permissions, real HTTP requests and security checks have all been verified on the target host. The Android client has not yet been wired to every endpoint.


## Persistent bookmarks (2026-11-02)

The Android client now syncs saved posts with the authenticated API.

For an existing database, run the additive migration once:

```sql
SOURCE migrations/2026_11_02_bookmarks.sql;
```

Alternatively, execute the SQL statements in that migration using phpMyAdmin. Do not drop or recreate the existing database.

Endpoints:
- `GET /v1/bookmarks` — list the signed-in user's saved posts.
- `POST /v1/posts/{id}/bookmark` — save a post.
- `DELETE /v1/posts/{id}/bookmark` — remove a saved post.

The full-install `schema.sql` also includes the bookmarks table for new installations.


## Interactive polls (2026-11-02)

Android supports creating a poll with 2–4 unique options in the post composer. The poll question is the post text. Vote totals and each option's result are returned in the post payload. A signed-in user can change their vote; one vote per user per poll is enforced by the database primary key.

For an existing database, back it up and run `migrations/2026_11_02_polls.sql` once in phpMyAdmin. This migration only creates the poll tables and does not remove existing records.

Endpoints:
- `POST /v1/posts` with optional `poll_options: ["Option A", "Option B"]`
- `POST /v1/polls/{pollId}/vote` with `{"option_id": 123}`

The API validates that an option belongs to the specified poll. The full-install `schema.sql` includes all poll tables.
