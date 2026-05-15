import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../models/classroom_location_model.dart';

class ClassroomLocationService {
  const ClassroomLocationService({required this.userId});

  final String userId;

  Future<List<ClassroomLocationModel>> listLocations() async {
    final data = await Api.call('location.list');
    final items = (data['locations'] as List? ?? const []);
    return items
        .whereType<Map>()
        .map(
          (item) =>
              ClassroomLocationModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> save(ClassroomLocationModel location) async {
    await Api.call(
      location.id.isEmpty ? 'location.create' : 'location.update',
      data: location.toMap(),
    );
  }

  Future<void> delete(String id) async {
    await Api.call('location.delete', data: {'id': id});
  }

  Future<void> openAppleMaps(ClassroomLocationModel location) async {
    final url =
        location.appleMapsUrl ??
        _buildAppleMapsUrl(
          address: location.address,
          latitude: location.latitude,
          longitude: location.longitude,
        );
    await _launchExternal(url);
  }

  Future<void> openGoogleMaps(ClassroomLocationModel location) async {
    final url =
        location.googleMapsUrl ??
        _buildGoogleMapsUrl(
          address: location.address,
          latitude: location.latitude,
          longitude: location.longitude,
        );
    await _launchExternal(url);
  }

  Future<void> openAppleMapsUrl(String url) => _launchExternal(url);

  Future<void> openGoogleMapsUrl(String url) => _launchExternal(url);

  String buildAppleMapsUrl({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    return _buildAppleMapsUrl(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  String buildGoogleMapsUrl({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    return _buildGoogleMapsUrl(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Không mở được ứng dụng bản đồ.');
    }
  }

  static String _buildAppleMapsUrl({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return 'https://maps.apple.com/?ll=$latitude,$longitude&q=${Uri.encodeComponent(address)}';
    }
    return 'https://maps.apple.com/?q=${Uri.encodeComponent(address)}';
  }

  static String _buildGoogleMapsUrl({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
  }
}
