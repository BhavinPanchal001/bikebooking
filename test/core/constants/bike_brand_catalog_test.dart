import 'package:bikebooking/core/constants/bike_brand_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brandAndModelOptions includes parent brands and model options', () {
    final options = BikeBrandCatalog.brandAndModelOptions;

    expect(options, contains('Triumph'));
    expect(options, contains('Triumph Speed Twin'));
    expect(options, contains('Triumph Street Scrambler [2019-2020]'));
    expect(options, contains('Royal Enfield Hunter 350'));
  });

  test('mergeWith keeps catalog model options and custom listing brands', () {
    final options = BikeBrandCatalog.mergeWith(<String>[
      'Custom Imported Bike',
      'Triumph Speed Twin',
    ]);

    expect(options, contains('Triumph Speed Twin'));
    expect(options, contains('Custom Imported Bike'));
    expect(options.where((option) => option == 'Triumph Speed Twin'),
        hasLength(1));
  });
}
