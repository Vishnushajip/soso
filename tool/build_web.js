// Clean web build + completeness check. Runs automatically before
// `firebase deploy` (see "predeploy" in firebase.json).
//
// Why: Flutter's incremental web build can skip copying web/ files
// (manifest.json, icons, ads.txt, AssetManifest/FontManifest…) while still
// reporting success. Deploying such a build leaves the site stuck on the
// splash because Firebase serves index.html for every missing file.
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const out = path.join(root, 'build', 'web');

for (const dir of [out, path.join(root, '.dart_tool', 'flutter_build')]) {
  fs.rmSync(dir, { recursive: true, force: true });
}

execSync('flutter build web --release', { cwd: root, stdio: 'inherit', shell: true });

// Flutter build web skips copying custom root files like ads.txt and app-ads.txt.
// Ensure they are always copied from web/ into build/web.
const webDir = path.join(root, 'web');
for (const file of ['ads.txt', 'app-ads.txt']) {
  const src = path.join(webDir, file);
  const dest = path.join(out, file);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, dest);
  }
}

// Generate AssetManifest fallback if not produced by modern Flutter compiler
const assetManifestPath = path.join(out, 'assets', 'AssetManifest.bin.json');
if (!fs.existsSync(assetManifestPath) && fs.existsSync(path.join(out, 'assets'))) {
  fs.writeFileSync(assetManifestPath, '{}', 'utf8');
}

const required = [
  'index.html',
  'main.dart.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'ads.txt',
  'app-ads.txt',
  'firebase-messaging-sw.js',
  'icons/Icon-512.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
];
const missing = required.filter((f) => !fs.existsSync(path.join(out, f)));
if (missing.length) {
  console.error('\nWeb build is incomplete, refusing to deploy. Missing:\n  ' + missing.join('\n  '));
  process.exit(1);
}
console.log('\nWeb build verified: all required files present.');
