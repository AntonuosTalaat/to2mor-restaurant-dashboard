class SettingModel {
  final String? id;
  final bool autoAssignToBranches;
  final CompaniesModel companies;
  final List<String> phoneNumbers;
  final List<String> emails;
  final FAQsModel faqs;
  final double deliveryPricePerKilo;
  final List<String> categories;
  final bool allRestaurantsStatus; // true for open, false for closed
  final DateTime updatedAt;
  final String customAddress;
  final double latitude;
  final double longitude;

  // ✅ الحقول الجديدة
  final bool isCourierSignupEnabled;
  final bool isRestaurantSignupEnabled;
  final bool isCompanySignupEnabled;

  SettingModel({
    this.id,
    required this.autoAssignToBranches,
    required this.companies,
    required this.phoneNumbers,
    required this.emails,
    required this.faqs,
    required this.deliveryPricePerKilo,
    required this.categories,
    required this.allRestaurantsStatus,
    required this.updatedAt,
    required this.customAddress,
    required this.latitude,
    required this.longitude,
    this.isCourierSignupEnabled = true,
    this.isRestaurantSignupEnabled = true,
    this.isCompanySignupEnabled = true,
  });

  factory SettingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SettingModel(
      id: documentId,
      autoAssignToBranches: map['autoAssignToBranches'] ?? false,
      companies: CompaniesModel.fromMap(map['companies'] ?? {}),
      phoneNumbers: List<String>.from(map['phoneNumbers'] ?? []),
      emails: List<String>.from(map['emails'] ?? []),
      faqs: FAQsModel.fromMap(map['faqs'] ?? {}),
      deliveryPricePerKilo: (map['deliveryPricePerKilo'] ?? 0.0).toDouble(),
      categories: List<String>.from(map['categories'] ?? []),
      allRestaurantsStatus: map['allRestaurantsStatus'] ?? true,
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
      customAddress: map['customAddress'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),

      // ✅ تحميل القيم من Firestore
      isCourierSignupEnabled: map['isCourierSignupEnabled'] ?? true,
      isRestaurantSignupEnabled: map['isRestaurantSignupEnabled'] ?? true,
      isCompanySignupEnabled: map['isCompanySignupEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoAssignToBranches': autoAssignToBranches,
      'companies': companies.toMap(),
      'phoneNumbers': phoneNumbers,
      'emails': emails,
      'faqs': faqs.toMap(),
      'deliveryPricePerKilo': deliveryPricePerKilo,
      'categories': categories,
      'allRestaurantsStatus': allRestaurantsStatus,
      'updatedAt': updatedAt,
      'customAddress': customAddress,
      'latitude': latitude,
      'longitude': longitude,

      // ✅ الحقول الجديدة
      'isCourierSignupEnabled': isCourierSignupEnabled,
      'isRestaurantSignupEnabled': isRestaurantSignupEnabled,
      'isCompanySignupEnabled': isCompanySignupEnabled,
    };
  }

  SettingModel copyWith({
    String? id,
    bool? autoAssignToBranches,
    CompaniesModel? companies,
    List<String>? phoneNumbers,
    List<String>? emails,
    FAQsModel? faqs,
    double? deliveryPricePerKilo,
    List<String>? categories,
    bool? allRestaurantsStatus,
    DateTime? updatedAt,
    String? customAddress,
    double? latitude,
    double? longitude,
    bool? isCourierSignupEnabled,
    bool? isRestaurantSignupEnabled,
    bool? isCompanySignupEnabled,
  }) {
    return SettingModel(
      id: id ?? this.id,
      autoAssignToBranches: autoAssignToBranches ?? this.autoAssignToBranches,
      companies: companies ?? this.companies,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emails: emails ?? this.emails,
      faqs: faqs ?? this.faqs,
      deliveryPricePerKilo: deliveryPricePerKilo ?? this.deliveryPricePerKilo,
      categories: categories ?? this.categories,
      allRestaurantsStatus: allRestaurantsStatus ?? this.allRestaurantsStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      customAddress: customAddress ?? this.customAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,

      // ✅ copyWith للحقول الجديدة
      isCourierSignupEnabled: isCourierSignupEnabled ?? this.isCourierSignupEnabled,
      isRestaurantSignupEnabled: isRestaurantSignupEnabled ?? this.isRestaurantSignupEnabled,
      isCompanySignupEnabled: isCompanySignupEnabled ?? this.isCompanySignupEnabled,
    );
  }
}


class CompaniesModel {
  final BranchCompanyModel branchCompany;
  final MainCompanyModel mainCompany;

  CompaniesModel({
    required this.branchCompany,
    required this.mainCompany,
  });

  factory CompaniesModel.fromMap(Map<String, dynamic> map) {
    return CompaniesModel(
      branchCompany: BranchCompanyModel.fromMap(map['branchCompany'] ?? {}),
      mainCompany: MainCompanyModel.fromMap(map['mainCompany'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchCompany': branchCompany.toMap(),
      'mainCompany': mainCompany.toMap(),
    };
  }
}

class BranchCompanyModel {
  final bool isAutoAssignOrder;

  BranchCompanyModel({
    required this.isAutoAssignOrder,
  });

  factory BranchCompanyModel.fromMap(Map<String, dynamic> map) {
    return BranchCompanyModel(
      isAutoAssignOrder: map['isAutoAssignOrder'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isAutoAssignOrder': isAutoAssignOrder,
    };
  }
}

class MainCompanyModel {
  final bool isAutoAssignOrder;

  MainCompanyModel({
    required this.isAutoAssignOrder,
  });

  factory MainCompanyModel.fromMap(Map<String, dynamic> map) {
    return MainCompanyModel(
      isAutoAssignOrder: map['isAutoAssignOrder'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isAutoAssignOrder': isAutoAssignOrder,
    };
  }
}

class FAQsModel {
  final List<FAQItem> userFAQs;
  final List<FAQItem> restaurantFAQs;
  final List<FAQItem> courierFAQs;

  FAQsModel({
    required this.userFAQs,
    required this.restaurantFAQs,
    required this.courierFAQs,
  });

  factory FAQsModel.fromMap(Map<String, dynamic> map) {
    return FAQsModel(
      userFAQs: (map['userFAQs'] as List<dynamic>?)
          ?.map((item) => FAQItem.fromMap(item))
          .toList() ??
          [],
      restaurantFAQs: (map['restaurantFAQs'] as List<dynamic>?)
          ?.map((item) => FAQItem.fromMap(item))
          .toList() ??
          [],
      courierFAQs: (map['courierFAQs'] as List<dynamic>?)
          ?.map((item) => FAQItem.fromMap(item))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userFAQs': userFAQs.map((item) => item.toMap()).toList(),
      'restaurantFAQs': restaurantFAQs.map((item) => item.toMap()).toList(),
      'courierFAQs': courierFAQs.map((item) => item.toMap()).toList(),
    };
  }
}

class FAQItem {
  final String question;
  final String answer;
  final bool isActive;

  FAQItem({
    required this.question,
    required this.answer,
    this.isActive = true,
  });

  factory FAQItem.fromMap(Map<String, dynamic> map) {
    return FAQItem(
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'isActive': isActive,
    };
  }
}
