import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocationModel {
  const UserLocationModel({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.label = '',
  });

  final String address;
  final double latitude;
  final double longitude;
  final String label;

  bool get isComplete =>
      address.trim().isNotEmpty && latitude != 0 && longitude != 0;

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
    };
  }

  factory UserLocationModel.fromMap(Map<String, dynamic> map) {
    return UserLocationModel(
      address: map['address']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      label: map['label']?.toString() ?? '',
    );
  }
}

class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.phoneNumber,
    this.fullName = '',
    this.email = '',
    this.registeredMobileNumber = '',
    this.photoUrl = '',
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String phoneNumber;
  final String fullName;
  final String email;
  final String registeredMobileNumber;
  final String photoUrl;
  final UserLocationModel? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasLocation => location?.isComplete ?? false;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (phoneNumber.trim().isNotEmpty) {
      return phoneNumber.trim();
    }
    return 'User';
  }

  String get primaryEmail =>
      email.trim().isNotEmpty ? email.trim() : 'Add your email';

  String get primaryPhone {
    if (phoneNumber.trim().isNotEmpty) {
      return phoneNumber.trim();
    }
    if (registeredMobileNumber.trim().isNotEmpty) {
      return registeredMobileNumber.trim();
    }
    return 'Add your phone number';
  }

  AppUserModel copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? email,
    String? registeredMobileNumber,
    String? photoUrl,
    UserLocationModel? location,
    bool clearLocation = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      registeredMobileNumber:
          registeredMobileNumber ?? this.registeredMobileNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      location: clearLocation ? null : (location ?? this.location),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'email': email,
      'registeredMobileNumber': registeredMobileNumber,
      'photoUrl': photoUrl,
      'location': location?.toMap(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final locationMap = map['location'];
    return AppUserModel(
      id: documentId,
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      registeredMobileNumber: map['registeredMobileNumber']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString() ?? '',
      location: locationMap is Map<String, dynamic>
          ? UserLocationModel.fromMap(locationMap)
          : locationMap is Map
              ? UserLocationModel.fromMap(
                  Map<String, dynamic>.from(locationMap))
              : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
