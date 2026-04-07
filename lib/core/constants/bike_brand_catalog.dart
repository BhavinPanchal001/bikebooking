class BikeBrandCatalog {
  const BikeBrandCatalog._();

  static const List<String> brands = <String>[
    'Ampere',
    'Aprilia',
    'Ather',
    'Bajaj',
    'Benelli',
    'BMW',
    'BSA',
    'CFMoto',
    'Ducati',
    'Harley-Davidson',
    'Hero',
    'Honda',
    'Hop Electric',
    'Husqvarna',
    'Jawa',
    'Kawasaki',
    'Keeway',
    'KTM',
    'LML',
    'Mahindra',
    'Moto Guzzi',
    'Oben',
    'Okinawa',
    'Ola Electric',
    'Other',
    'PURE EV',
    'QJ Motor',
    'Revolt',
    'Royal Enfield',
    'Simple Energy',
    'Suzuki',
    'TVS',
    'Tork',
    'Triumph',
    'Ultraviolette',
    'Vespa',
    'Vida',
    'Yamaha',
    'Yezdi',
  ];

  static List<String> mergeWith(Iterable<String> brands) {
    final merged = <String>{...BikeBrandCatalog.brands};
    for (final brand in brands) {
      final trimmed = brand.trim();
      if (trimmed.isNotEmpty) {
        merged.add(trimmed);
      }
    }

    final sorted = merged.toList(growable: false)
      ..sort((first, second) =>
          first.toLowerCase().compareTo(second.toLowerCase()));
    return sorted;
  }
}
