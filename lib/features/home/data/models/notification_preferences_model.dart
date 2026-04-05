class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    this.allNotifications = true,
    this.adListing = true,
    this.newMessage = true,
    this.viewedAd = true,
    this.expiringSoon = true,
    this.paymentFailed = true,
    this.subscriptionReminder = false,
  });

  static const NotificationPreferencesModel defaults =
      NotificationPreferencesModel();

  final bool allNotifications;
  final bool adListing;
  final bool newMessage;
  final bool viewedAd;
  final bool expiringSoon;
  final bool paymentFailed;
  final bool subscriptionReminder;

  NotificationPreferencesModel copyWith({
    bool? allNotifications,
    bool? adListing,
    bool? newMessage,
    bool? viewedAd,
    bool? expiringSoon,
    bool? paymentFailed,
    bool? subscriptionReminder,
  }) {
    return NotificationPreferencesModel(
      allNotifications: allNotifications ?? this.allNotifications,
      adListing: adListing ?? this.adListing,
      newMessage: newMessage ?? this.newMessage,
      viewedAd: viewedAd ?? this.viewedAd,
      expiringSoon: expiringSoon ?? this.expiringSoon,
      paymentFailed: paymentFailed ?? this.paymentFailed,
      subscriptionReminder: subscriptionReminder ?? this.subscriptionReminder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allNotifications': allNotifications,
      'adListing': adListing,
      'newMessage': newMessage,
      'viewedAd': viewedAd,
      'expiringSoon': expiringSoon,
      'paymentFailed': paymentFailed,
      'subscriptionReminder': subscriptionReminder,
    };
  }

  bool isTypeEnabled(String type) {
    switch (type.trim().toLowerCase()) {
      case 'message':
        return newMessage;
      case 'listing':
      case 'listing_update':
        return adListing;
      case 'product_view':
        return viewedAd;
      case 'listing_expiring':
      case 'expiring_soon':
        return expiringSoon;
      case 'payment_failed':
        return paymentFailed;
      case 'subscription':
      case 'subscription_expiring':
      case 'subscription_reminder':
        return subscriptionReminder;
      default:
        return allNotifications;
    }
  }

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return defaults;
    }

    bool readBool(String key, bool fallback) {
      final value = map[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') {
          return true;
        }
        if (normalized == 'false') {
          return false;
        }
      }
      return fallback;
    }

    return NotificationPreferencesModel(
      allNotifications: readBool('allNotifications', true),
      adListing: readBool('adListing', true),
      newMessage: readBool('newMessage', true),
      viewedAd: readBool('viewedAd', true),
      expiringSoon: readBool('expiringSoon', true),
      paymentFailed: readBool('paymentFailed', true),
      subscriptionReminder: readBool('subscriptionReminder', false),
    );
  }
}
