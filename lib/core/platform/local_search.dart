import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String name;
  final String address;
  final double lat;
  final double lng;
}

/// iOS限定: MapKit(MKLocalSearch)による店舗名検索。
/// AppDelegate.swiftのMethodChannel実装と対になっている。
class LocalSearch {
  static const _channel = MethodChannel('culturetune/local_search');

  static bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<List<PlaceResult>> search(
    String query, {
    double? lat,
    double? lng,
  }) async {
    if (!isSupported || query.trim().isEmpty) return const [];
    try {
      final results = await _channel.invokeMethod<List<Object?>>('search', {
        'query': query.trim(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      return [
        for (final r in results ?? const [])
          if (r is Map)
            PlaceResult(
              name: r['name'] as String? ?? '',
              address: r['address'] as String? ?? '',
              lat: (r['lat'] as num).toDouble(),
              lng: (r['lng'] as num).toDouble(),
            ),
      ];
    } on PlatformException {
      return const [];
    }
  }
}
