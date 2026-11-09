flutter build web --release --no-tree-shake-icons
firebase deploy --only hosting
flutter build apk --release


# Update Version Commands

# Increment Patch Version

dart update_version.dart patch

# Increment Minor Version

dart update_version.dart minor

# Increment Major Version

dart update_version.dart major

# Decrement Patch Version

dart update_version.dart patch decrement

# Decrement Minor Version

dart update_version.dart minor decrement

# Decrement Major Version

dart update_version.dart major decrement



# Environment variables

Configuration is read from a local `.env` file (never commit it). Copy the template and fill in real values:

```bash
cp .env.example .env
```

Variables: `APP_NAME`, `SUPPORT_EMAIL`, `GOOGLE_CLIENT_ID_WEB`, `GOOGLE_SERVER_CLIENT_ID`,
`PRESENCE_HEARTBEAT_SECONDS`, `BOARD_SIZE`, `ENABLE_CRASHLYTICS`, `ENABLE_ANALYTICS`,
`FCM_SERVICE_ACCOUNT_JSON`. See `.env.example` for placeholders.
