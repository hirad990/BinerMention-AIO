# BinerMention PHP API

Deploy the contents of this folder to the cPanel document root mapped to `https://binercraft.ir/mention-api-pub/`.

## Initial endpoint

- `GET /` — API health and version response.

## Before production

1. Create a MariaDB database and a dedicated database user in cPanel.
2. Store credentials in environment variables or a configuration file outside the public document root; do not commit credentials.
3. Add authentication, authorization, input validation, rate limiting, CSRF protection where applicable, upload validation, and prepared SQL statements before exposing account or social endpoints.
4. Configure CORS for the web client’s exact origin, rather than allowing every origin by default.
5. Use HTTPS and test the API from an Android device.

This is an initial deployment skeleton, not yet a production-ready social-network backend. The Android screen currently contains local demonstration posts; persistence and account features require the remaining API implementation.