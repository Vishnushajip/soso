flutter build web --release
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



flutter clean
flutter pub get
flutter build web --release
firebase deploy --only hosting