import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomMap extends StatelessWidget {
  final List<Marker> markers;
  final MapController mapController;

  const CustomMap({
    Key? key,
    required this.markers,
    required this.mapController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: markers.isNotEmpty ? markers[0].point : LatLng(0, 0),
        //zoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: markers,
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => Uri.parse('https://openstreetmap.org/copyright'),
            ),
          ],
        ),
      ],
    );
  }
}
