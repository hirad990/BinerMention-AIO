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
- `GET /v1/users/{username}`, `GET /v1/users/{id}/posts`, `GET /v1/users/{id}/followers`, `GET /v1/users/{id}/following`
- `GET /v1/search/posts?q=hashtag` — search posts containing a hashtag
- `GET /v1/posts`, `POST /v1/posts`, `GET /v1/posts/{id}`, `PATCH /v1/posts/{id}`, `DELETE /v1/posts/{id}`
- `POST /v1/posts/{id}/like`, `DELETE /v1/posts/{id}/like`
- `POST /v1/posts/{id}/repost`, `DELETE /v1/posts/{id}/repost`
- `POST /v1/users/{id}/follow`, `DELETE /v1/users/{id}/follow`
- `POST /v1/media` (multipart form field named `file`), `DELETE /v1/media/{id}`
- `GET /v1/notifications`, `POST /v1/notifications/{id}/read`, `POST /v1/notifications/read-all`
- `GET /v1/conversations`, `POST /v1/conversations` with `user_id`
- `GET /v1/conversations/{id}/messages`, `POST /v1/conversations/{id}/messages`, `POST /v1/conversations/{id}/read`

## Register example

```http
POST /v1/auth/register
Content-Type: application/json

{"username":"test_user","email":"test@example.com","password":"use-a-long-unique-password","display_name":"Test User"}
```

The API is not considered production-ready until schema import, DB credentials, PHP extensions, file permissions, real HTTP requests and security checks have all been verified on the target host. The Android client has not yet been wired to every endpoint.
