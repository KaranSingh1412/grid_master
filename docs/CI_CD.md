# CI/CD

Zwei GitHub-Workflows, beide unter `.github/workflows/`:

- `ci.yml`: bei jedem Pull Request und jedem Push auf `main` und `claude/**`. Prüft Format, `flutter analyze` und `flutter test`.
- `release.yml`: bei einem Tag `v*` (z. B. `v1.0.2`) oder per Hand („Run workflow“, Plattform wählbar). Baut und lädt hoch:
  - Android über `android/fastlane` → Google Play, Track `internal`
  - iOS über `ios/fastlane` → TestFlight

Die Versionsnummer (`1.0.1`) kommt aus `pubspec.yaml`. Die Build-Nummer wird automatisch hochgezählt: höchster Code in Google Play bzw. TestFlight + 1.

## Einrichtung in GitHub

Settings → Environments → `release` anlegen. Dort diese Secrets eintragen:

| Secret | Inhalt |
| --- | --- |
| `ENV_FILE` | kompletter Inhalt der lokalen `.env` |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` aus `android/key.properties` |
| `ANDROID_KEY_ALIAS` | `keyAlias` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` |
| `PLAY_STORE_JSON_KEY` | JSON-Schlüssel eines Google-Cloud-Service-Accounts (Inhalt der Datei) |
| `APP_STORE_CONNECT_KEY_ID` | Key-ID des App-Store-Connect-API-Keys |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer-ID |
| `APP_STORE_CONNECT_KEY_P8_BASE64` | `base64 -i AuthKey_XXXX.p8` |
| `APPLE_TEAM_ID` | Team-ID (10 Zeichen) |
| `IOS_DIST_CERT_P12_BASE64` | `base64 -i distribution.p12` |
| `IOS_DIST_CERT_PASSWORD` | Passwort der `.p12` |

Optional als Environment-Variablen (nicht Secrets):

- `PLAY_TRACK`: `internal` (Standard), `alpha`, `beta` oder `production`
- `PLAY_RELEASE_STATUS`: `completed` (Standard) oder `draft`. Solange die App in Google Play noch nie veröffentlicht wurde, muss hier `draft` stehen.

## Einmalig außerhalb von GitHub

Google Play:

1. Die App in der Play Console anlegen und das erste AAB einmal von Hand hochladen. Erst danach geht der API-Upload.
2. In der Google Cloud Console einen Service Account mit JSON-Key anlegen und die „Google Play Android Developer API“ aktivieren.
3. In der Play Console unter „Nutzer und Berechtigungen“ den Service Account einladen und ihm Release-Rechte für die App geben.

Apple:

1. App Store Connect → Nutzer und Zugriff → Integrationen → API-Key mit Rolle „App Manager“ anlegen und die `.p8` herunterladen.
2. Ein „Apple Distribution“-Zertifikat aus dem Schlüsselbund als `.p12` exportieren.
3. Im Developer-Portal für die App-ID `de.karancode.gridMaster` die Capability „Game Center“ aktivieren. Das App-Store-Profil erstellt fastlane selbst.
4. Die App in App Store Connect anlegen.

## Lokal

```sh
cd android && bundle install && bundle exec fastlane android deploy
cd ios && bundle install && bundle exec fastlane ios deploy
```

Dafür müssen dieselben Werte wie oben als Umgebungsvariablen gesetzt sein.
