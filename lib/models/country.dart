/// Représente un pays dans l'application.
class AppCountry {
  final String code;
  final String name;
  final String flagEmoji;

  const AppCountry({
    required this.code,
    required this.name,
    required this.flagEmoji,
  });

  static const all = [
    AppCountry(code: 'FR', name: 'France', flagEmoji: '🇫🇷'),
    AppCountry(code: 'TR', name: 'Turquie', flagEmoji: '🇹🇷'),
    AppCountry(code: 'BE', name: 'Belgique', flagEmoji: '🇧🇪'),
    AppCountry(code: 'CH', name: 'Suisse', flagEmoji: '🇨🇭'),
    AppCountry(code: 'CA', name: 'Canada', flagEmoji: '🇨🇦'),
    AppCountry(code: 'GB', name: 'Royaume-Uni', flagEmoji: '🇬🇧'),
    AppCountry(code: 'US', name: 'États-Unis', flagEmoji: '🇺🇸'),
    AppCountry(code: 'DE', name: 'Allemagne', flagEmoji: '🇩🇪'),
    AppCountry(code: 'ES', name: 'Espagne', flagEmoji: '🇪🇸'),
    AppCountry(code: 'IT', name: 'Italie', flagEmoji: '🇮🇹'),
  ];

  static AppCountry fromCode(String code) {
    return all.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => all.first,
    );
  }
}
