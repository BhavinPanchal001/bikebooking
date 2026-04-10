import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

Future<bool> executeNotificationNavigation({
  required ProductFirestoreService productFirestoreService,
  String? type,
  String? targetRoute,
  String? productId,
  String? chatId,
  String? fallbackRoute,
}) async {
  final destination = _resolveNotificationDestination(
    type: type,
    targetRoute: targetRoute,
    productId: productId,
    chatId: chatId,
  );

  if (destination == null) {
    return _openNamed(fallbackRoute);
  }

  if (destination.productId != null) {
    try {
      final product = await productFirestoreService.getProductById(
        destination.productId!,
      );
      if (product != null) {
        Get.toNamed('/bike_detail', arguments: product);
        return true;
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Error loading product for notification navigation: $error\n$stackTrace',
      );
    }

    return _openNamed(fallbackRoute);
  }

  return _openNamed(destination.route, arguments: destination.arguments) ||
      _openNamed(fallbackRoute);
}

_NotificationDestination? _resolveNotificationDestination({
  String? type,
  String? targetRoute,
  String? productId,
  String? chatId,
}) {
  final normalizedType = (type ?? '').trim().toLowerCase();
  final normalizedRoute = (targetRoute ?? '').trim();
  final normalizedProductId = (productId ?? '').trim();
  final normalizedChatId = (chatId ?? '').trim();

  if (normalizedRoute.isNotEmpty) {
    if (normalizedRoute == '/chat_detail') {
      if (normalizedChatId.isNotEmpty) {
        return _NotificationDestination(
          route: normalizedRoute,
          arguments: normalizedChatId,
        );
      }
      return const _NotificationDestination(route: '/messages');
    }

    if (normalizedRoute != '/bike_detail') {
      return _NotificationDestination(route: normalizedRoute);
    }
  }

  switch (normalizedType) {
    case 'message':
      if (normalizedChatId.isNotEmpty) {
        return _NotificationDestination(
          route: '/chat_detail',
          arguments: normalizedChatId,
        );
      }
      return const _NotificationDestination(route: '/messages');
    case 'listing':
    case 'listing_update':
    case 'product_view':
    case 'listing_expiring':
    case 'expiring_soon':
      return const _NotificationDestination(route: '/my_listing');
    case 'payment_failed':
    case 'subscription':
    case 'subscription_expiring':
    case 'subscription_reminder':
      return const _NotificationDestination(route: '/subscription_status');
    default:
      break;
  }

  if (normalizedRoute == '/bike_detail' && normalizedProductId.isNotEmpty) {
    return _NotificationDestination.product(normalizedProductId);
  }

  if (normalizedProductId.isNotEmpty) {
    return _NotificationDestination.product(normalizedProductId);
  }

  return null;
}

bool _openNamed(String? route, {Object? arguments}) {
  final normalizedRoute = route?.trim() ?? '';
  if (normalizedRoute.isEmpty) {
    return false;
  }

  if (arguments != null) {
    Get.toNamed(normalizedRoute, arguments: arguments);
  } else {
    Get.toNamed(normalizedRoute);
  }

  return true;
}

class _NotificationDestination {
  const _NotificationDestination({
    required this.route,
    this.arguments,
    this.productId,
  });

  const _NotificationDestination.product(String productId)
      : this(route: '/bike_detail', productId: productId);

  final String route;
  final Object? arguments;
  final String? productId;
}
