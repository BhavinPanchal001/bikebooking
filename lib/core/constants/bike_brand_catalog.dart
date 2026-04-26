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

  static const Map<String, List<String>> brandModels = <String, List<String>>{
    'Aprilia': <String>[
      'RS 457',
      'RS 660',
      'RSV4',
      'SR 125',
      'SR 160',
      'SXR 125',
      'SXR 160',
      'Tuareg 660',
    ],
    'Ather': <String>[
      '450 Apex',
      '450S',
      '450X',
      'Rizta',
    ],
    'Bajaj': <String>[
      'Avenger Cruise 220',
      'Avenger Street 160',
      'Chetak',
      'CT 110X',
      'Dominar 250',
      'Dominar 400',
      'Pulsar 125',
      'Pulsar 150',
      'Pulsar N150',
      'Pulsar N160',
      'Pulsar NS125',
      'Pulsar NS160',
      'Pulsar NS200',
      'Pulsar RS200',
      'Pulsar 220F',
    ],
    'Benelli': <String>[
      'Imperiale 400',
      'Leoncino 500',
      'TRK 502',
      'TRK 502X',
    ],
    'BMW': <String>[
      'C 400 GT',
      'F 900 GS',
      'G 310 GS',
      'G 310 R',
      'G 310 RR',
      'R 1250 GS',
      'R 1300 GS',
      'S 1000 RR',
    ],
    'Ducati': <String>[
      'Diavel V4',
      'Hypermotard 950',
      'Monster',
      'Multistrada V4',
      'Panigale V2',
      'Panigale V4',
      'Scrambler Icon',
      'Streetfighter V4',
    ],
    'Harley-Davidson': <String>[
      'Fat Boy',
      'Iron 883',
      'Nightster',
      'Sportster S',
      'Street 750',
      'X440',
    ],
    'Hero': <String>[
      'Destini 125',
      'Glamour',
      'HF Deluxe',
      'Karizma XMR',
      'Maestro Edge',
      'Mavrick 440',
      'Passion Pro',
      'Pleasure Plus',
      'Splendor Plus',
      'Super Splendor',
      'Xoom',
      'XPulse 200',
      'Xtreme 125R',
      'Xtreme 160R',
      'Xtreme 200S',
    ],
    'Honda': <String>[
      'Activa 6G',
      'Activa 125',
      'CB200X',
      'CB300F',
      'CB300R',
      'CB350',
      'CB350RS',
      'Dio',
      'Hness CB350',
      'Hornet 2.0',
      'Livo',
      'Shine',
      'SP 125',
      'Unicorn',
      'X-Blade',
    ],
    'Husqvarna': <String>[
      'Svartpilen 250',
      'Svartpilen 401',
      'Vitpilen 250',
      'Vitpilen 401',
    ],
    'Jawa': <String>[
      '42',
      '42 Bobber',
      '350',
      'Perak',
    ],
    'Kawasaki': <String>[
      'Eliminator',
      'Ninja 300',
      'Ninja 400',
      'Ninja 500',
      'Ninja 650',
      'Ninja ZX-10R',
      'Versys 650',
      'Z650',
      'Z900',
    ],
    'KTM': <String>[
      '125 Duke',
      '200 Duke',
      '250 Adventure',
      '250 Duke',
      '390 Adventure',
      '390 Duke',
      'RC 125',
      'RC 200',
      'RC 390',
    ],
    'Okinawa': <String>[
      'iPraise+',
      'Lite',
      'PraisePro',
      'R30',
      'Ridge+',
    ],
    'Ola Electric': <String>[
      'S1 Air',
      'S1 Pro',
      'S1 X',
      'S1 X+',
    ],
    'Royal Enfield': <String>[
      'Bullet 350',
      'Classic 350',
      'Continental GT 650',
      'Guerrilla 450',
      'Himalayan',
      'Himalayan 450',
      'Hunter 350',
      'Interceptor 650',
      'Meteor 350',
      'Scram 411',
      'Shotgun 650',
      'Super Meteor 650',
    ],
    'Suzuki': <String>[
      'Access 125',
      'Avenis',
      'Burgman Street',
      'Gixxer',
      'Gixxer SF',
      'Gixxer SF 250',
      'Hayabusa',
      'Katana',
      'V-Strom SX',
    ],
    'TVS': <String>[
      'Apache RTR 160',
      'Apache RTR 160 4V',
      'Apache RTR 180',
      'Apache RTR 200 4V',
      'Apache RR 310',
      'iQube',
      'Jupiter',
      'Ntorq 125',
      'Raider 125',
      'Ronin',
      'Scooty Pep Plus',
      'Sport',
      'Star City Plus',
      'XL100',
      'X',
    ],
    'Tork': <String>[
      'Kratos',
      'Kratos R',
    ],
    'Triumph': <String>[
      'Bonneville Bobber',
      'Bonneville Speedmaster',
      'Bonneville T100',
      'Bonneville T120',
      'Rocket 3',
      'Scrambler 400 X',
      'Scrambler 900',
      'Speed 400',
      'Speed Triple 1200RR',
      'Speed Triple ABS',
      'Speed Twin',
      'Speed Twin 900',
      'Speed Twin 1200',
      'Speed Twin [2019-2020]',
      'Speed Twin [2021]',
      'Street Cup-2003',
      'Street Scrambler',
      'Street Scrambler [2018]',
      'Street Scrambler [2019-2020]',
      'Street Triple 675 ABS',
      'Tiger 660',
      'Tiger 850 Sport',
      'Tiger 900',
      'Tiger 1200',
      'Trident 660',
    ],
    'Ultraviolette': <String>[
      'F77',
      'F77 Mach 2',
    ],
    'Vespa': <String>[
      'Elegante 150',
      'SXL 125',
      'SXL 150',
      'VXL 125',
      'VXL 150',
      'ZX 125',
    ],
    'Vida': <String>[
      'V1 Plus',
      'V1 Pro',
    ],
    'Yamaha': <String>[
      'Aerox 155',
      'Fascino 125',
      'FZ FI',
      'FZ-X',
      'FZS FI',
      'MT-15',
      'R15 V4',
      'RayZR 125',
      'R3',
    ],
    'Yezdi': <String>[
      'Adventure',
      'Roadster',
      'Scrambler',
    ],
  };

  static List<String> get brandAndModelOptions {
    final options = <String>{...brands};
    for (final entry in brandModels.entries) {
      for (final model in entry.value) {
        final trimmedModel = model.trim();
        if (trimmedModel.isNotEmpty) {
          options.add('${entry.key} $trimmedModel');
        }
      }
    }

    final sorted = options.toList(growable: false)
      ..sort((first, second) =>
          first.toLowerCase().compareTo(second.toLowerCase()));
    return sorted;
  }

  static List<String> mergeWith(Iterable<String> brands) {
    final merged = <String>{...BikeBrandCatalog.brandAndModelOptions};
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
