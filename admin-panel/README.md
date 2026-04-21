# BikeBooking Admin Panel

A separate React admin panel for the Flutter `bikebooking` project.

## Run locally

```bash
cd admin-panel
npm install
npm run dev
```

The Vite dev server runs on `http://localhost:5174`.

## Firebase setup

1. Copy `.env.example` to `.env.local`.
2. Add your Firebase web app credentials.
3. Restart the dev server.

For temporary local-only access while wiring admin claims, you can set:

```bash
VITE_BYPASS_ADMIN_AUTH=true
```

This bypass is respected only in the Vite dev server and still requires Firebase sign-in.

Without Firebase config, the admin panel uses curated demo data that matches the current BikeBooking marketplace domain:

- users
- products/listings
- chats
- seller reports
- seller reviews

## Included pages

- Dashboard overview
- Listing moderation
- User directory
- Inbox and safety watchlist
