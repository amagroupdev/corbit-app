/// Settings for the Noor / Madrasati certification platforms.
///
/// Maps to the JSON returned by `GET /certifications/settings`
/// and accepted by `POST /certifications/settings/{noor|madrasati}`.
class CertificationSettingsModel {
  const CertificationSettingsModel({
    this.noorMessageBody,
    this.madrasatiMessageBody,
    this.senderName,
    this.isNoorEnabled = true,
    this.isMadrasatiEnabled = false,
  });

  final String? noorMessageBody;
  final String? madrasatiMessageBody;
  final String? senderName;
  final bool isNoorEnabled;
  final bool isMadrasatiEnabled;

  factory CertificationSettingsModel.fromJson(Map<String, dynamic> json) {
    final noor = json['noor'];
    final madrasati = json['madrasati'];

    String? noorBody;
    String? madrasatiBody;

    if (noor is Map<String, dynamic>) {
      noorBody = noor['message_body'] as String?;
    } else {
      noorBody = json['noor_message_body'] as String?;
    }

    if (madrasati is Map<String, dynamic>) {
      madrasatiBody = madrasati['message_body'] as String?;
    } else {
      madrasatiBody = json['madrasati_message_body'] as String?;
    }

    return CertificationSettingsModel(
      noorMessageBody: noorBody,
      madrasatiMessageBody: madrasatiBody,
      senderName: json['sender_name'] as String?,
      isNoorEnabled: json['is_noor_enabled'] as bool? ?? true,
      isMadrasatiEnabled: json['is_madrasati_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (noorMessageBody != null) 'noor_message_body': noorMessageBody,
      if (madrasatiMessageBody != null)
        'madrasati_message_body': madrasatiMessageBody,
      if (senderName != null) 'sender_name': senderName,
      'is_noor_enabled': isNoorEnabled,
      'is_madrasati_enabled': isMadrasatiEnabled,
    };
  }

  CertificationSettingsModel copyWith({
    String? noorMessageBody,
    String? madrasatiMessageBody,
    String? senderName,
    bool? isNoorEnabled,
    bool? isMadrasatiEnabled,
  }) {
    return CertificationSettingsModel(
      noorMessageBody: noorMessageBody ?? this.noorMessageBody,
      madrasatiMessageBody: madrasatiMessageBody ?? this.madrasatiMessageBody,
      senderName: senderName ?? this.senderName,
      isNoorEnabled: isNoorEnabled ?? this.isNoorEnabled,
      isMadrasatiEnabled: isMadrasatiEnabled ?? this.isMadrasatiEnabled,
    );
  }
}

/// Filter options returned by `GET /certifications/filter-options`.
class CertificationFilterOptionsModel {
  const CertificationFilterOptionsModel({
    this.statuses = const [],
    this.platforms = const [],
    this.profiles = const [],
  });

  final List<String> statuses;
  final List<String> platforms;
  final List<Map<String, dynamic>> profiles;

  factory CertificationFilterOptionsModel.fromJson(Map<String, dynamic> json) {
    return CertificationFilterOptionsModel(
      statuses: (json['statuses'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      platforms: (json['platforms'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      profiles: (json['profiles'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
    );
  }
}
