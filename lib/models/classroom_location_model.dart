import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ClassroomLocationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ClassroomLocationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      scheduleId: data['scheduleId'] as String? ?? '',
      roomName: data['roomName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      appleMapsUrl: data['appleMapsUrl'] as String?,
      googleMapsUrl: data['googleMapsUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'scheduleId': scheduleId,
      'roomName': roomName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'appleMapsUrl': appleMapsUrl,
      'googleMapsUrl': googleMapsUrl,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
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
}
