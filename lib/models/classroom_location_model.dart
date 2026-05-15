class ClassroomLocationModel {
  const ClassroomLocationModel({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.roomName,
    required this.address,
    this.latitude,
    this.longitude,
    this.appleMapsUrl,
    this.googleMapsUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String scheduleId;
  final String roomName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? appleMapsUrl;
  final String? googleMapsUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasLocation =>
      address.trim().isNotEmpty || (latitude != null && longitude != null);

  factory ClassroomLocationModel.fromMap(Map<String, dynamic> data) {
    return ClassroomLocationModel(
      id: (data['id'] ?? '').toString(),
      userId: (data['userId'] ?? data['user_id'] ?? '').toString(),
      scheduleId: (data['scheduleId'] ?? data['schedule_id'] ?? '').toString(),
      roomName: (data['roomName'] ?? data['room_name'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      appleMapsUrl:
          data['appleMapsUrl']?.toString() ??
          data['apple_maps_url']?.toString(),
      googleMapsUrl:
          data['googleMapsUrl']?.toString() ??
          data['google_maps_url']?.toString(),
      createdAt: _readDate(data['createdAt'] ?? data['created_at']),
      updatedAt: _readDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'scheduleId': scheduleId,
      'roomName': roomName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'appleMapsUrl': appleMapsUrl,
      'googleMapsUrl': googleMapsUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ClassroomLocationModel copyWith({
    String? roomName,
    String? address,
    double? latitude,
    double? longitude,
    String? appleMapsUrl,
    String? googleMapsUrl,
  }) {
    return ClassroomLocationModel(
      id: id,
      userId: userId,
      scheduleId: scheduleId,
      roomName: roomName ?? this.roomName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      appleMapsUrl: appleMapsUrl ?? this.appleMapsUrl,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
