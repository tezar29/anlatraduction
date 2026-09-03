Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
  var current = json;
  for (final key in ['data', 'result', 'payload', 'user', 'profile', 'entitlements']) {
    final candidate = current[key];
    if (candidate is Map) {
      current = Map<String, dynamic>.from(candidate);
      break;
    }
  }
  if (current['subscription'] is Map && current['plan'] == null) {
    final subscription = _asMap(current['subscription']);
    current = {...subscription, ...current};
  }
  return current;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    this.id = '',
    this.code = 'FREE',
    this.name = 'Free',
    this.description = '',
    this.priceAmount = 0,
    this.currency = 'EUR',
    this.billingPeriod = 'MONTHLY',
    this.audioMinutesLimit = 0,
    this.translatedCharactersLimit = 0,
    this.ttsCharactersLimit = 0,
    this.conversationsLimit = 0,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final num priceAmount;
  final String currency;
  final String billingPeriod;
  final int audioMinutesLimit;
  final int translatedCharactersLimit;
  final int ttsCharactersLimit;
  final int conversationsLimit;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: '${json['id'] ?? ''}',
        code: '${json['code'] ?? 'FREE'}',
        name: '${json['name'] ?? json['code'] ?? 'Free'}',
        description: '${json['description'] ?? ''}',
        priceAmount: json['priceAmount'] ?? 0,
        currency: '${json['currency'] ?? 'EUR'}',
        billingPeriod: '${json['billingPeriod'] ?? 'MONTHLY'}',
        audioMinutesLimit: int.tryParse('${json['audioMinutesLimit'] ?? 0}') ?? 0,
        translatedCharactersLimit:
            int.tryParse('${json['translatedCharactersLimit'] ?? 0}') ?? 0,
        ttsCharactersLimit: int.tryParse('${json['ttsCharactersLimit'] ?? 0}') ?? 0,
        conversationsLimit: int.tryParse('${json['conversationsLimit'] ?? 0}') ?? 0,
      );
}

class UserSubscription {
  const UserSubscription({
    this.id = '',
    this.userId = '',
    this.plan = const SubscriptionPlan(),
    this.status = 'PENDING',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEnd,
    this.canceledAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final String status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final DateTime? canceledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value == '') return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final base = _unwrapPayload(json);
    final nested = base['subscription'] is Map ? _asMap(base['subscription']) : base;
    final planMap = nested['plan'] is Map ? _asMap(nested['plan']) : const <String, dynamic>{};

    return UserSubscription(
      id: '${nested['id'] ?? base['id'] ?? ''}',
      userId: '${nested['userId'] ?? base['userId'] ?? ''}',
      plan: SubscriptionPlan.fromJson(planMap),
      status: '${nested['status'] ?? base['status'] ?? 'PENDING'}',
      currentPeriodStart: parseDate(nested['currentPeriodStart'] ?? base['currentPeriodStart']),
      currentPeriodEnd: parseDate(nested['currentPeriodEnd'] ?? base['currentPeriodEnd']),
      trialEnd: parseDate(nested['trialEnd'] ?? base['trialEnd']),
      canceledAt: parseDate(nested['canceledAt'] ?? base['canceledAt']),
      createdAt: parseDate(nested['createdAt'] ?? base['createdAt']),
      updatedAt: parseDate(nested['updatedAt'] ?? base['updatedAt']),
    );
  }
}

class UserProfile {
  const UserProfile({
    this.id = '',
    this.email = '',
    this.fullName = '',
    this.preferredLanguage = 'fr',
    this.country = '',
    this.timezone = '',
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String fullName;
  final String preferredLanguage;
  final String country;
  final String timezone;
  final bool emailVerified;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    return UserProfile(
      id: '${base['id'] ?? ''}',
      email: '${base['email'] ?? ''}',
      fullName: '${base['fullName'] ?? base['name'] ?? ''}',
      preferredLanguage: '${base['preferredLanguage'] ?? base['primaryLanguage'] ?? 'fr'}',
      country: '${base['country'] ?? ''}',
      timezone: '${base['timezone'] ?? ''}',
      emailVerified: base['emailVerified'] == true,
    );
  }
}

class Entitlements {
  const Entitlements({this.planCode = 'FREE', this.limits = const {}, this.features = const {}});

  final String planCode;
  final Map<String, dynamic> limits;
  final Map<String, dynamic> features;

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    return Entitlements(
      planCode: '${base['planCode'] ?? base['plan'] ?? 'FREE'}',
      limits: _asMap(base['limits']),
      features: _asMap(base['features']),
    );
  }
}

class BillingInvoice {
  const BillingInvoice({
    this.id = '',
    this.subscriptionId = '',
    this.amount = 0,
    this.currency = 'EUR',
    this.status = 'OPEN',
    this.createdAt,
    this.dueDate,
    this.paidAt,
  });

  final String id;
  final String subscriptionId;
  final num amount;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final DateTime? dueDate;
  final DateTime? paidAt;

  factory BillingInvoice.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    DateTime? parseDate(dynamic value) {
      if (value == null || value == '') return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return BillingInvoice(
      id: '${base['id'] ?? base['invoiceId'] ?? ''}',
      subscriptionId: '${base['subscriptionId'] ?? base['subscription_id'] ?? ''}',
      amount: base['amount'] ?? 0,
      currency: '${base['currency'] ?? 'EUR'}',
      status: '${base['status'] ?? 'OPEN'}',
      createdAt: parseDate(base['createdAt'] ?? base['created_at']),
      dueDate: parseDate(base['dueDate'] ?? base['due_date']),
      paidAt: parseDate(base['paidAt'] ?? base['paid_at']),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    this.id = '',
    this.invoiceId = '',
    this.provider = 'stripe',
    this.providerReference = '',
    this.amount = 0,
    this.currency = 'EUR',
    this.status = 'PENDING',
    this.createdAt,
    this.confirmedAt,
  });

  final String id;
  final String invoiceId;
  final String provider;
  final String providerReference;
  final num amount;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    DateTime? parseDate(dynamic value) {
      if (value == null || value == '') return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return PaymentRecord(
      id: '${base['id'] ?? base['paymentId'] ?? ''}',
      invoiceId: '${base['invoiceId'] ?? base['invoice_id'] ?? ''}',
      provider: '${base['provider'] ?? 'stripe'}',
      providerReference: '${base['providerReference'] ?? base['provider_reference'] ?? ''}',
      amount: base['amount'] ?? 0,
      currency: '${base['currency'] ?? 'EUR'}',
      status: '${base['status'] ?? 'PENDING'}',
      createdAt: parseDate(base['createdAt'] ?? base['created_at']),
      confirmedAt: parseDate(base['confirmedAt'] ?? base['confirmed_at']),
    );
  }
}

class Conversation {
  const Conversation({required this.id, this.title = 'Conversation', this.status = 'NEW', this.sourceLanguage = 'fr', this.targetLanguage = 'tr'});

  final String id;
  final String title;
  final String status;
  final String sourceLanguage;
  final String targetLanguage;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: '${json['id'] ?? json['conversationId'] ?? ''}',
        title: '${json['title'] ?? 'Conversation'}',
        status: '${json['status'] ?? 'NEW'}',
        sourceLanguage: '${json['sourceLanguage'] ?? 'fr'}',
        targetLanguage: '${json['targetLanguage'] ?? 'tr'}',
      );
}

class Speaker {
  const Speaker({required this.id, required this.name, this.active = false});

  final String id;
  final String name;
  final bool active;

  factory Speaker.fromJson(Map<String, dynamic> json) => Speaker(
        id: '${json['id'] ?? json['speakerId'] ?? ''}',
        name: '${json['name'] ?? json['displayName'] ?? 'Locuteur'}',
        active: json['active'] == true || json['isActive'] == true,
      );
}

class TtsGeneration {
  const TtsGeneration({
    this.id = '',
    this.conversationId = '',
    this.messageId = '',
    this.provider = 'tts',
    this.inputText = '',
    this.languageCode = 'fr',
    this.voiceName = '',
    this.voiceGender = '',
    this.speakingRate = 0,
    this.pitch = 0,
    this.audioFormat = 'mp3',
    this.audioUri = '',
    this.status = 'COMPLETED',
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String messageId;
  final String provider;
  final String inputText;
  final String languageCode;
  final String voiceName;
  final String voiceGender;
  final num speakingRate;
  final num pitch;
  final String audioFormat;
  final String audioUri;
  final String status;
  final DateTime? createdAt;

  factory TtsGeneration.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    DateTime? parseDate(dynamic value) {
      if (value == null || value == '') return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return TtsGeneration(
      id: '${base['id'] ?? ''}',
      conversationId: '${base['conversationId'] ?? base['conversation_id'] ?? ''}',
      messageId: '${base['messageId'] ?? base['message_id'] ?? ''}',
      provider: '${base['provider'] ?? 'tts'}',
      inputText: '${base['inputText'] ?? base['text'] ?? ''}',
      languageCode: '${base['languageCode'] ?? base['language_code'] ?? 'fr'}',
      voiceName: '${base['voiceName'] ?? base['voice_name'] ?? ''}',
      voiceGender: '${base['voiceGender'] ?? base['voice_gender'] ?? ''}',
      speakingRate: base['speakingRate'] ?? 0,
      pitch: base['pitch'] ?? 0,
      audioFormat: '${base['audioFormat'] ?? base['audio_format'] ?? 'mp3'}',
      audioUri: '${base['audioUri'] ?? base['audio_url'] ?? base['audioUrl'] ?? ''}',
      status: '${base['status'] ?? 'COMPLETED'}',
      createdAt: parseDate(base['createdAt'] ?? base['created_at']),
    );
  }
}

class GuestSession {
  const GuestSession({
    this.id = '',
    this.deviceId = '',
    this.displayName = '',
    this.sourceLanguage = 'fr',
    this.targetLanguage = 'tr',
    this.status = 'ACTIVE',
    this.claimedByUserId = '',
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String deviceId;
  final String displayName;
  final String sourceLanguage;
  final String targetLanguage;
  final String status;
  final String claimedByUserId;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GuestSession.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    DateTime? parseDate(dynamic value) {
      if (value == null || value == '') return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return GuestSession(
      id: '${base['id'] ?? ''}',
      deviceId: '${base['deviceId'] ?? ''}',
      displayName: '${base['displayName'] ?? base['name'] ?? ''}',
      sourceLanguage: '${base['sourceLanguage'] ?? 'fr'}',
      targetLanguage: '${base['targetLanguage'] ?? 'tr'}',
      status: '${base['status'] ?? 'ACTIVE'}',
      claimedByUserId: '${base['claimedByUserId'] ?? base['claimedByUser'] ?? ''}',
      expiresAt: parseDate(base['expiresAt'] ?? base['expires_at']),
      createdAt: parseDate(base['createdAt'] ?? base['created_at']),
      updatedAt: parseDate(base['updatedAt'] ?? base['updated_at']),
    );
  }
}

class LanguagePack {
  const LanguagePack({
    this.code = '',
    this.name = '',
    this.nativeName = '',
    this.description = '',
    this.version = '',
    this.offlineAvailable = false,
    this.recommended = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final String description;
  final String version;
  final bool offlineAvailable;
  final bool recommended;

  factory LanguagePack.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    return LanguagePack(
      code: '${base['code'] ?? base['languageCode'] ?? base['slug'] ?? ''}',
      name: '${base['name'] ?? base['displayName'] ?? base['title'] ?? base['code'] ?? ''}',
      nativeName: '${base['nativeName'] ?? base['native_name'] ?? base['localeName'] ?? ''}',
      description: '${base['description'] ?? ''}',
      version: '${base['version'] ?? base['currentVersion'] ?? base['installedVersion'] ?? ''}',
      offlineAvailable: base['offlineAvailable'] == true ||
          base['isOfflineAvailable'] == true ||
          base['downloadable'] == true,
      recommended: base['recommended'] == true || base['isRecommended'] == true,
    );
  }
}

class LanguagePackInstallation {
  const LanguagePackInstallation({
    this.id = '',
    this.userId = '',
    this.languageCode = '',
    this.deviceId = '',
    this.installedVersion = '',
    this.installedAt,
  });

  final String id;
  final String userId;
  final String languageCode;
  final String deviceId;
  final String installedVersion;
  final DateTime? installedAt;

  factory LanguagePackInstallation.fromJson(Map<String, dynamic> json) {
    final base = _unwrapPayload(json);
    DateTime? parseDate(dynamic value) {
      if (value == null || value == '') return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return LanguagePackInstallation(
      id: '${base['id'] ?? ''}',
      userId: '${base['userId'] ?? base['user_id'] ?? ''}',
      languageCode: '${base['languageCode'] ?? base['code'] ?? base['language_code'] ?? ''}',
      deviceId: '${base['deviceId'] ?? base['device_id'] ?? ''}',
      installedVersion: '${base['installedVersion'] ?? base['version'] ?? ''}',
      installedAt: parseDate(base['installedAt'] ?? base['installed_at'] ?? base['createdAt']),
    );
  }
}
