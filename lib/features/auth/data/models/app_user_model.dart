import 'package:cloud_firestore/cloud_firestore.dart';

String _normalizeAccountStatus(
  Object? rawStatus, {
  bool adminBlocked = false,
}) {
  if (adminBlocked) {
    return 'blocked';
  }

  final normalizedStatus = rawStatus?.toString().trim().toLowerCase() ?? '';
  return normalizedStatus == 'blocked' ? 'blocked' : 'active';
}

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
    this.accountStatus = 'active',
    this.adminBlocked = false,
    this.adminBlockedAt,
    this.adminBlockedBy = '',
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
  final String accountStatus;
  final bool adminBlocked;
  final DateTime? adminBlockedAt;
  final String adminBlockedBy;
  final UserLocationModel? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasLocation => location?.isComplete ?? false;
  bool get isBlocked => adminBlocked || accountStatus == 'blocked';

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return '';
  }

  String get displayNameLabel {
    final name = displayName;
    return name.isNotEmpty ? name : 'User';
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
    String? accountStatus,
    bool? adminBlocked,
    DateTime? adminBlockedAt,
    String? adminBlockedBy,
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
      accountStatus: _normalizeAccountStatus(
        accountStatus ?? this.accountStatus,
        adminBlocked: adminBlocked ?? this.adminBlocked,
      ),
      adminBlocked: adminBlocked ?? this.adminBlocked,
      adminBlockedAt: adminBlockedAt ?? this.adminBlockedAt,
      adminBlockedBy: adminBlockedBy ?? this.adminBlockedBy,
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
      'accountStatus': accountStatus,
      'adminBlocked': adminBlocked,
      'location': location?.toMap(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final locationMap = map['location'];
    final adminBlocked = map['adminBlocked'] == true;
    return AppUserModel(
      id: documentId,
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      registeredMobileNumber: map['registeredMobileNumber']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString() ?? '',
      accountStatus: _normalizeAccountStatus(
        map['accountStatus'],
        adminBlocked: adminBlocked,
      ),
      adminBlocked: adminBlocked,
      adminBlockedAt: (map['adminBlockedAt'] as Timestamp?)?.toDate(),
      adminBlockedBy: map['adminBlockedBy']?.toString() ?? '',
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
