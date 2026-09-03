# Traducteur — Turc ↔ Français / Anglais

Interfaces Flutter modernes pour une app de traduction (texte + voix).
Le backend (moteur de traduction) sera branché par ton collègue.

## Installation

```bash
flutter pub get
flutter run
```

Pour utiliser le backend, fournir son URL et le jeton d’accès courant :

```bash
flutter run --dart-define=API_BASE_URL=https://api.anla.mybestsejour.com --dart-define=ACCESS_TOKEN=votre-token
```

L’écran principal appelle `POST /api/v1/translations` avec `text`,
`sourceLanguage` et `targetLanguage`. Le jeton doit être obtenu via le
parcours `POST /api/v1/auth/login` décrit dans la documentation backend.

## Structure

```
lib/
  main.dart                  # Point d'entrée + navigation (3 onglets)
  theme/app_theme.dart       # Couleurs, typographie (Material 3)
  models/
    language.dart            # Langues supportées (tr, fr, en)
    translation_entry.dart   # Un élément de l'historique
  services/
    translation_service.dart # ⚠️ Contrat pour le backend (voir plus bas)
    voice_service.dart       # Reconnaissance vocale + synthèse vocale
  providers/app_state.dart   # État global (Provider)
  widgets/
    language_bar.dart        # Sélecteur de langues + bouton inverser
    input_card.dart          # Zone de saisie texte/voix
    output_card.dart         # Résultat + écoute + copie
  screens/
    translate_screen.dart    # Écran principal
    history_screen.dart      # Historique des traductions
    settings_screen.dart     # Thème clair/sombre/auto
```

## Pour ton collègue (backend)

Un seul fichier à modifier : `lib/services/translation_service.dart`.
Il doit créer une classe qui implémente `TranslationService` :

```dart
class ApiTranslationService implements TranslationService {
  @override
  Future<String> translate({
    required String text,
    required String sourceLangCode, // "tr", "fr", "en"
    required String targetLangCode,
  }) async {
    // appel à votre API ici
  }
}
```

Puis dans `main.dart`, remplacer :
```dart
translationService: MockTranslationService(),
```
par :
```dart
translationService: ApiTranslationService(),
```

Le reste de l'app (interfaces, historique, voix, thème) n'a rien à changer.

## Permissions micro à ajouter

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSMicrophoneUsageDescription</key>
<string>L'application a besoin du micro pour la traduction vocale.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>L'application utilise la reconnaissance vocale pour traduire votre voix.</string>
```

## Fonctionnalités incluses

- Sélection turc → français/anglais avec bouton d'inversion
- Saisie de texte ou dictée vocale (speech_to_text)
- Lecture audio de la traduction (flutter_tts)
- Historique persistant (SharedPreferences) avec favoris et suppression
- Thème clair/sombre/auto, design Material 3 moderne
- Navigation par barre du bas (3 onglets)
