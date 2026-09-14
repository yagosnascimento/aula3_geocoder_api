import 'dart:async';

import 'package:aula3_geocoder_api/models/estado.dart';
import 'package:aula3_geocoder_api/models/geocode_result.dart';
import 'package:aula3_geocoder_api/services/estados_service.dart';
import 'package:aula3_geocoder_api/services/nominatim_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// flutter run -d web-server
// Nominatim

/*
  q = query

  https://nominatim.openstreetmap.org/
    search?q=funda%C3%A7%C3%A3o%20educacional%20do%20Munic%C3%ADpio%20de%20Assis
    &format=jsonv2&namedetails=0&addressdetails=1
    &limit=1
*/

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final NominatimService nominatimService = NominatimService();

  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  GeocodeResult? _geocodeResult;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {
          _geocodeResult = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String? query) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(const Duration(seconds: 3), () async {
      _geocodeResult = await widget.nominatimService.search(query);

      print(_geocodeResult);

      if (_geocodeResult == null) {
        _searchController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha na consulta ao serviço. Tente novamente'),
              backgroundColor: Colors.red.shade900,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App Geocoder API')),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_outlined),
                ),
              ),
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            _geocodeResult == null
                ? const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.0),
                        Text(
                          'Aguardando pesquisa ...',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 16.0),
                        SizedBox(
                          width: double.infinity,
                          height: 32.0,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MapPage(geocodeResult: _geocodeResult!),
                                ),
                              );
                            },
                            child: Text('Visualizar Mapa'),
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Expanded(
                          child: ListView(
                            children: _geocodeResult!.getAttributes().map((
                              entry,
                            ) {
                              return Padding(
                                padding: EdgeInsetsGeometry.symmetric(
                                  vertical: 12.0,
                                  horizontal: 32.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        textAlign: TextAlign.end,
                                        style: TextStyle(fontSize: 12.0),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  final GeocodeResult geocodeResult;

  const MapPage({super.key, required this.geocodeResult});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  double currentZoom = 5.0;
  MapController mapController = MapController();
  final EstadosService estadosService = EstadosService();
  List<Estado> estados = [];

  @override
  void initState() {
    super.initState();
    carregarEstados();
  }

  Future<void> carregarEstados() async {
    try {
      final resultado = await estadosService.buscarEstados();

      if (mounted) {
        setState(() {
          estados = resultado;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nao foi possivel carregar os estados'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map Viewer')),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: LatLng(-14.2, -51.9),
          initialZoom: currentZoom,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.edu.fema',
          ),
          MarkerLayer(
            markers: [
              ...estados.map((estado) {
                return Marker(
                  point: LatLng(estado.latitude, estado.longitude),
                  width: 90.0,
                  height: 60.0,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(estado.nome),
                          content: Text(
                            'UF: ${estado.uf}\n'
                            'Regiao: ${estado.regiao}\n'
                            'Codigo: ${estado.codigoUf}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Fechar'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Icon(
                      Icons.location_on,
                      size: 26.0,
                      color: Colors.blue.shade700,
                    ),
                  ),
                );
              }),
              Marker(
                point: getLatLong(),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: Text('Detalhes da Pesquisa'),
                        content: Text(widget.geocodeResult.address.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Fechar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.location_pin,
                    size: 32.0,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8.0,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            onPressed: () => zoomIn(),
            child: Icon(Icons.zoom_in_outlined),
          ),
          FloatingActionButton(
            heroTag: 'zoomOut',
            onPressed: () => zoomOut(),
            child: Icon(Icons.zoom_out_outlined),
          ),
          FloatingActionButton(
            heroTag: 'zoomRestore',
            onPressed: () => zoomRestore(),
            backgroundColor: Colors.orange.shade900,
            child: Icon(Icons.restore_outlined),
          ),
        ],
      ),
    );
  }

  LatLng getLatLong() {
    final latitude = double.parse(widget.geocodeResult.latitude);
    final longitude = double.parse(widget.geocodeResult.longitude);
    return LatLng(latitude, longitude);
  }

  void zoomIn() {
    currentZoom += 1.0;
    update();
  }

  void zoomOut() {
    currentZoom -= 1.0;
    update();
  }

  void zoomRestore() {
    currentZoom = 5.0;
    update();
  }

  void update() {
    mapController.move(getLatLong(), currentZoom);
  }
}
