import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:diagnostico/components/map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng _seleccionUbicacion = const LatLng(-4.00064661, -79.20426114);
  final List<Marker> _marcadores = [];
  final MapController mapController = MapController();
  String selectedCategory = 'Restaurantes'; // Categoría seleccionada

  @override
  void initState() {
    super.initState();
    _verificarUbicacion();
  }

  // Verificar la ubicación y permisos
  void _verificarUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      _mostrarMensajePermiso();
      return;
    }
    var estado = await Permission.location.status;
    if (estado.isGranted) {
      _obtenerUbicacionActual();
    } else if (estado.isDenied) {
      if (await Permission.location.request().isGranted) {
        _obtenerUbicacionActual();
      }
    } else if (estado.isPermanentlyDenied) {
      _mostrarMensajePermiso();
    }
  }

  // Obtener la ubicación actual
  void _obtenerUbicacionActual() async {
    Position posicion = await Geolocator.getCurrentPosition();
    setState(() {
      _seleccionUbicacion = LatLng(posicion.latitude, posicion.longitude);
    });
    buscarLugares(); // Buscar lugares después de obtener la ubicación
  }

  // Buscar lugares cercanos
  void buscarLugares() async {
    const double radioBusqueda = 50; // Radio de búsqueda (50 km)

    try {
      List<Place> lugares = await buscarLugaresPorCategoria(
        selectedCategory,
        _seleccionUbicacion.latitude,
        _seleccionUbicacion.longitude,
        radioBusqueda,
      );

      setState(() {
        _marcadores.clear();
        // Agregar marcador de ubicación actual
        _marcadores.add(Marker(
          width: 80.0,
          height: 80.0,
          point: _seleccionUbicacion,
          child: const Icon(
            Icons.my_location_rounded,
            color: Colors.blue,
            size: 40,
          ),
        ));

        // Agregar marcadores de lugares encontrados
        for (var lugar in lugares) {
          _marcadores.add(Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(lugar.lat, lugar.lon),
            child: const Icon(Icons.location_on, color: Colors.green, size: 40),
          ));
        }
        // Mover el mapa a la primera ubicación
        if (_marcadores.isNotEmpty) {
          mapController.move(_marcadores[0].point, 15.0);
        }
      });
    } catch (e) {
      // Manejar error
      print("Error al buscar lugares: $e");
    }
  }

  // Método para buscar lugares por categoría
  Future<List<Place>> buscarLugaresPorCategoria(
      String categoria, double latitud, double longitud, double radio) async {
    double minLat = latitud - (radio / 111.32);
    double maxLat = latitud + (radio / 111.32);
    double minLon = longitud - (radio / (111.32 * cos(latitud * pi / 180)));
    double maxLon = longitud + (radio / (111.32 * cos(latitud * pi / 180)));

    return await Nominatim.searchByName(
      query: categoria,
      limit: 50,
      viewBox: ViewBox(maxLat, minLat, maxLon, minLon),
      addressDetails: true,
      extraTags: true,
      nameDetails: true,
    );
  }

  // Mostrar mensaje de advertencia cuando el permiso de ubicación ha sido denegado
  void _mostrarMensajePermiso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ubicación desactivada"),
          content: const Text("Activa la ubicación para continuar"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async {
                var estado = await Permission.location.request();
                if (estado.isGranted) {
                  Navigator.of(context).pop();
                  _obtenerUbicacionActual();
                }
              },
              child: const Text("Activar ubicación"),
            ),
          ],
        );
      },
    );
  }

  void onCategoryChanged(String? newValue) {
    setState(() {
      selectedCategory = newValue!;
      buscarLugares(); // Volver a buscar lugares al cambiar la categoría
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Lugares'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              items: ['Restaurantes', 'Parques', 'Hoteles', 'Hospitales']
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: onCategoryChanged,
            ),
          ),
          Expanded(
            child: CustomMap(
              markers: _marcadores,
              mapController: mapController,
            ),
          ),
        ],
      ),
    );
  }
}
