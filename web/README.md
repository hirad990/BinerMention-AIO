# BinerMention Web
Next.js App Router + React + TypeScript web client for the same PHP API used by the Flutter Android app.

Stack: Tailwind CSS v4/CSS variables, Motion for React, Radix UI Avatar/Dropdown, Lucide React, TanStack Query, Zod, Zustand-compatible local session persistence, Vitest and Playwright.

```bash
cd web
cp .env.example .env.local
npm install
npm run dev
```
API base defaults to `https://binercraft.ir/mention-api-pub`; add the web origin to the PHP API CORS allowlist.
`npm run build` produces a static export in `out/`, suitable for cPanel/static hosting. GitHub Actions validates types and unit tests, then uploads `BinerMention-web-dist`.
Routes used: auth login/register/logout, /v1/me, posts create/feed/like/repost, user search/profile/follow, post search, conversations/messages and notifications.
