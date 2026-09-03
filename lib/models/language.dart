/// Représente une langue disponible dans l'application.
/// [code] doit correspondre au code attendu par l'API du backend
/// (ex : "tr", "fr", "en") et [speechLocale] au code utilisé par
/// speech_to_text / flutter_tts (ex : "tr-TR", "fr-FR", "en-US").
class AppLanguage {
  final String code;
  final String label;
  final String flagEmoji;
  final String speechLocale;
  final bool isPackInstalled;
  final bool isRecommended;

  const AppLanguage({
    required this.code,
    required this.label,
    required this.flagEmoji,
    required this.speechLocale,
    this.isPackInstalled = false,
    this.isRecommended = false,
  });

  static const turkish = AppLanguage(
    code: 'tr',
    label: 'Turc',
    flagEmoji: '🇹🇷',
    speechLocale: 'tr-TR',
  );

  static const french = AppLanguage(
    code: 'fr',
    label: 'Français',
    flagEmoji: '🇫🇷',
    speechLocale: 'fr-FR',
  );

  static const english = AppLanguage(
    code: 'en',
    label: 'Anglais',
    flagEmoji: '🇬🇧',
    speechLocale: 'en-US',
  );

  /// Langues cibles possibles depuis le turc, selon la demande initiale.
  static const targets = [french, english];

  static const all = [turkish, french, english];
}
