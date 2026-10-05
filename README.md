# Masar Flutter App

Bilingual Flutter customer app for **Masar** vehicle services. Browse an office catalog, build a cart, complete guest checkout, upload documents, and track orders privately against the [masar-backend](https://github.com/itsyosefali/masar-backend) API. Arabic and English, RTL layouts, bundled fonts and vehicle illustration.

## Requirements

- Flutter 3.41+ (stable)
- A reachable Masar backend
- Android Studio / Xcode for native targets as needed

## Quick start

```sh
flutter pub get
flutter analyze
flutter test
```

### Web (browser)

Start the backend, then:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Or build a static web bundle:

```sh
flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=https://your-api.example
```

Production web hosting should share origin with the API (or configure CORS / same-origin proxy carefully). Backend `APP_ORIGIN` must match the browser origin for cookie-based staff flows; the customer app uses bearer order keys for guest tracking.

### Android emulator

```sh
flutter run -d <android-emulator-id> --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` reaches the host machine from the standard emulator.

### Physical Android device

Forward the phone to your machine’s backend (or use a LAN IP the phone can reach):

```sh
adb reverse tcp:8080 tcp:8080
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:8080
```

Debug builds allow HTTP for local development. Release builds should use HTTPS.

### iOS

```sh
flutter run -d <ios-simulator-id> --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

iOS builds need macOS, Xcode, and provisioning. Local HTTP may need a development ATS exception; production uses HTTPS.

### Release APK

```sh
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example
```

Android release signing requires your own keystore — do not commit keystores or `key.properties` with passwords.

## Build-time configuration

| Define | Purpose |
| --- | --- |
| `API_BASE_URL` | Backend origin. Defaults: current origin (web), `10.0.2.2:8080` (Android), `127.0.0.1:8080` (elsewhere) |
| `OFFICE_SLUG` | Optional initial office workspace ID |

A user’s saved office preference overrides `OFFICE_SLUG`.

## Customer flow

- Home, searchable catalog, service details and fee breakdown
- Office selection by workspace ID or storefront link
- Cart (up to eight services for one vehicle)
- Guest checkout: contact → vehicle → documents → review / payment preference
- Native file picker (PDF/JPEG/PNG), private order tracking, follow-up uploads
- Optional Moamalat local-card payment via hosted WebView (secrets stay on the backend)

No customer login is created by guest checkout. Order tracking keys are stored with `flutter_secure_storage` on device.

## API surface

| Operation | Endpoint |
| --- | --- |
| Catalog | `GET /api/public/offices/{slug}` |
| Checkout | `POST /api/public/offices/{slug}/orders` |
| Tracking | `GET /api/public/offices/{slug}/order` |
| Extra document | `POST /api/public/offices/{slug}/order/documents` |

Amounts are integer thousandths of LYD. Tracking uses `Authorization: Bearer <order-key>`.

## Related repositories

| Repo | Role |
| --- | --- |
| [masar-backend](https://github.com/itsyosefali/masar-backend) | Go + SQLite API |
| [masar-frontend](https://github.com/itsyosefali/masar-frontend) | Astro staff dashboard + storefront |

## Security notes

- Never put Moamalat secure keys, API tokens, or keystores in this repo or in `--dart-define` values that ship to clients.
- `.env`, keystores, and signing passwords are gitignored.
- Guest tracking capabilities are high-entropy; treat them like session secrets on device.

## License

Private / all rights reserved unless otherwise stated by the owner.
