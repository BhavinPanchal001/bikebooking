import 'package:bikebooking/core/config/demo_payments_config.dart';
import 'package:bikebooking/features/home/data/services/mock_payment_client_service.dart';
import 'package:bikebooking/features/home/data/services/payment_client_service.dart';

/// Returns the active [PaymentClient] implementation for the current
/// build. Release/CI builds always return the real
/// [PaymentClientService]; debug runs launched with
/// `--dart-define=USE_MOCK_PAYMENTS=true` get the
/// [MockPaymentClientService] instead.
PaymentClient createPaymentClient() {
  if (kUseMockPayments) {
    return MockPaymentClientService();
  }
  return PaymentClientService();
}
