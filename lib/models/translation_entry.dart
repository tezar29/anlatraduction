class TranslationEntry {
  final String id;
  final String sourceText;
  final String translatedText;
  final String sourceLangCode;
  final String targetLangCode;
  final DateTime date;
  final bool isFavorite;

  TranslationEntry({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLangCode,
    required this.targetLangCode,
    required this.date,
    this.isFavorite = false,
  });

  TranslationEntry copyWith({bool? isFavorite}) => TranslationEntry(
        id: id,
        sourceText: sourceText,
        translatedText: translatedText,
        sourceLangCode: sourceLangCode,
        targetLangCode: targetLangCode,
        date: date,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceText': sourceText,
        'translatedText': translatedText,
        'sourceLangCode': sourceLangCode,
        'targetLangCode': targetLangCode,
        'date': date.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory TranslationEntry.fromJson(Map<String, dynamic> json) =>
      TranslationEntry(
        id: json['id'],
        sourceText: json['sourceText'],
        translatedText: json['translatedText'],
        sourceLangCode: json['sourceLangCode'],
        targetLangCode: json['targetLangCode'],
        date: DateTime.parse(json['date']),
        isFavorite: json['isFavorite'] ?? false,
      );
}
