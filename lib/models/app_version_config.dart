class AppVersionConfig {
  const AppVersionConfig({
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateMessage,
    this.apkUrl,
  });

  final String latestVersion;
  final String minimumVersion;
  final String updateMessage;


  final String? apkUrl;

  factory AppVersionConfig.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const {};
    String str(List<String> keys, [String fallback = '']) {
      for (final k in keys) {
        final v = d[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return fallback;
    }

    final apk = str(['apk_url', 'apkUrl']);
    return AppVersionConfig(
      latestVersion: str(['latestVersion', 'latest_version']),
      minimumVersion: str(['minimumVersion', 'minimum_version']),
      updateMessage: str(
        ['updateMessage', 'update_message'],
        'A new version is available with improvements and bug fixes.',
      ),
      apkUrl: apk.isEmpty ? null : apk,
    );
  }
}
