# Deployment Guide

This guide covers deploying the Loom Monitoring System Flutter app to various platforms.

## Prerequisites

- Flutter 3.10+ with Dart 3.0+
- Platform-specific tools (see sections below)
- Backend API server running (see API_INTEGRATION.md)

## Web Deployment

### Build for Web

```bash
flutter clean
flutter pub get
flutter build web --release
```

### Output
Build files are generated in `build/web/`

### Deployment Options

#### 1. Firebase Hosting (Recommended)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase project
firebase init

# Deploy
firebase deploy
```

#### 2. Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=build/web
```

#### 3. GitHub Pages

```bash
# Add to pubspec.yaml
# homepage: https://yourusername.github.io/loom-monitoring-system

flutter build web --base-href=/loom-monitoring-system/

# Push build/web to gh-pages branch
git add build/web
git commit -m "Deploy to GitHub Pages"
git push origin build/web:gh-pages
```

#### 4. Docker Container

Create `Dockerfile`:
```dockerfile
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```bash
docker build -t loom-monitoring-system .
docker run -p 80:80 loom-monitoring-system
```

#### 5. Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel deploy --prod ./build/web
```

### Web Configuration

Create `web/index.html` modifications:
```html
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="Industrial Loom Monitoring System">
<title>Loom Monitoring System</title>
```

### Environment-Specific Configuration

Create `lib/config/environment.dart`:
```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );
  
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );
}
```

Build with custom values:
```bash
flutter build web \
  --dart-define=API_BASE_URL=https://api.example.com/api \
  --dart-define=WS_URL=wss://api.example.com/ws
```

---

## Desktop Deployment

### Windows

#### Build
```bash
flutter build windows --release
```

#### Output
`build/windows/runner/Release/loom_monitoring_system.exe`

#### Installation
1. Create installer using NSIS or MSI
2. Or distribute the executable directly

#### Create MSI Installer
```bash
# Install WiX Toolset from https://wixtoolset.org/

flutter build windows --release

# Create WiX configuration and run:
# (See WiX documentation)
```

### macOS

#### Build
```bash
flutter build macos --release
```

#### Output
`build/macos/Build/Products/Release/loom_monitoring_system.app`

#### Codesign
```bash
codesign -v --deep --strict \
  --options=runtime \
  --sign "Developer ID Application" \
  build/macos/Build/Products/Release/loom_monitoring_system.app
```

#### Create DMG
```bash
# Using create-dmg or similar tools
create-dmg \
  --volname "Loom Monitoring System" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --text-size 14 \
  --hdiutil-quiet \
  loom_monitoring_system.dmg \
  build/macos/Build/Products/Release/loom_monitoring_system.app
```

### Linux

#### Build
```bash
flutter build linux --release
```

#### Output
`build/linux/x64/release/bundle/loom_monitoring_system`

#### Create AppImage
```bash
# Install linuxdeployqt
# Follow AppImage creation process

./linuxdeployqt build/linux/x64/release/bundle/loom_monitoring_system \
  -appimage
```

#### Create Snap
```bash
# Create snapcraft.yaml in root directory
snapcraft
snap install --dangerous loom_monitoring_system_*.snap
```

#### Create Flatpak
```bash
# Create flatpak manifest and follow Flatseal documentation
flatpak-builder build-dir org.example.LoomMonitoringSystem.json
```

---

## Docker Deployment

### Multi-Stage Build for Web

```dockerfile
# Build stage
FROM cirrusci/flutter:latest as builder

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Runtime stage
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### nginx.conf for Flutter Web
```nginx
server {
  listen 80;
  
  location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;
  }
  
  # Proxy API requests
  location /api/ {
    proxy_pass http://backend:8080/api/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
  
  # WebSocket support
  location /ws {
    proxy_pass http://backend:8080/ws;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
  }
}
```

### Docker Compose

```yaml
version: '3.8'
services:
  frontend:
    build: .
    ports:
      - "80:80"
    environment:
      - API_BASE_URL=http://backend:8080/api
    depends_on:
      - backend
  
  backend:
    image: your-backend-image:latest
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
```

Run with:
```bash
docker-compose up -d
```

---

## CI/CD Pipeline

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

### GitLab CI Example

Create `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - deploy

build_web:
  stage: build
  image: cirrusci/flutter:latest
  script:
    - flutter pub get
    - flutter build web --release
  artifacts:
    paths:
      - build/web

deploy_web:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - curl -X POST -F "file=@build/web" $DEPLOY_URL
  only:
    - main
```

---

## Performance Optimization

### Web
```bash
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### Compression
- Enable GZIP compression on server
- Use CDN for static assets
- Minimize initial bundle size

### Caching
- Set appropriate cache headers
- Use service workers for offline support

---

## Monitoring & Analytics

### Add Firebase Analytics
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;
analytics.logEvent(name: 'loom_release', parameters: {'length': 4.0});
```

### Add Sentry for Error Tracking
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

await SentryFlutter.init(
  (options) => options.dsn = 'YOUR_SENTRY_DSN',
  appRunner: () => runApp(const LoomMonitoringApp()),
);
```

---

## Security Considerations

1. **HTTPS Only**: Always use HTTPS in production
2. **API Authentication**: Implement JWT or API keys
3. **CORS**: Properly configure CORS headers
4. **Rate Limiting**: Implement rate limiting on backend
5. **Input Validation**: Validate all user inputs
6. **Secrets**: Store API URLs and secrets securely

### Environment File (.env)
```
API_BASE_URL=https://api.example.com
WS_URL=wss://api.example.com/ws
API_KEY=your_secret_key
```

---

## Troubleshooting

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Performance Issues
- Check Network tab in DevTools
- Profile with `flutter run --profile`
- Analyze app size with `flutter build web --analyze-size`

### Deployment Issues
- Check server logs
- Verify API connectivity
- Check CORS configuration
- Review browser console for errors

---

## Rollback Procedure

### Firebase Hosting
```bash
firebase hosting:channel:deploy staging
firebase hosting:channels:list
firebase hosting:clone production staging
```

### Docker
```bash
docker pull image:previous-tag
docker run -d image:previous-tag
```

---

For more help, refer to the main README.md and API_INTEGRATION.md files.
