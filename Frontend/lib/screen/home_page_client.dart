import 'package:aluminios/models/usuario.dart';
import 'package:aluminios/repository/user_repository.dart';
import 'package:aluminios/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomePageClient extends StatefulWidget {
  const HomePageClient({super.key});

  @override
  State<HomePageClient> createState() => _HomePageClientState();
}

class _HomePageClientState extends State<HomePageClient>{

  String ? _name = "";
  bool _isLoged = false;

  final LatLng _coordenadasTaller = const LatLng(37.29436173988716, -4.871455574171553);
  final String _direccionTaller = "Calle Julio Romero de Torres, 19, bajo, Estepa";

  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async{
    try {
      Usuario user = await _userRepository.getCurrentUser() ;
      if (mounted){
        setState(() {
          _name = user.firstName;
          _isLoged = true;
        });
      }
    } catch (e) {
      setState(() {
        _name = "";
        _isLoged = false;
      });
    }
  }

  Widget _buildItemEspecialidad(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineaDetalle(String texto, {bool isCerrado = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 30,),
          const Icon(Icons.fiber_manual_record, color: Color(0xFF222B6F), size: 6),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool esMovil = screenWidth < 700;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(

                    child: Padding(
                        padding: esMovil
                            ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                            : EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Header(name: _name!, isLoged: _isLoged),
                          Padding(
                              padding:  esMovil
                              ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                              : EdgeInsets.symmetric(horizontal: screenWidth*0.07, vertical: 40),
                  //EdgeInsets.only(right: esMovil ? 20 : 100.0, left: esMovil ? 20 : 100.0, top: 20, bottom: 40),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.store_outlined, color: Color(0xFF222B6F), size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "QUIENES SOMOS",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF222B6F)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                const Text(
                                  "Somos una empresa líder especializada en carpintería metálica y cerramientos de aluminio. Nos dedicamos a transformar tus ideas en proyectos reales, garantizando la máxima durabilidad, aislamiento y diseño adaptado a las necesidades de tu hogar o local.",
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  children: [
                                    Icon(Icons.handyman_outlined, color: Color(0xFF222B6F), size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "QUE HACEMOS",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF222B6F)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    children: [
                                      _buildItemEspecialidad("Fabricación y montaje de ventanas de aluminio."),
                                      _buildItemEspecialidad("Puertas residenciales e industriales a medida."),
                                      _buildItemEspecialidad("Cerramientos térmicos, mamparas y estructuras."),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFAFC0E8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF222B6F)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.calculate_outlined, color: Color(0xFF222B6F), size: 22),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "¿Tienes un proyecto en mente? Comienza a diseñar tu presupuesto personalizado desde la sección de presupuestos. Si tienes cualquier duda, no dudes en contactarnos.",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF222B6F),
                                              fontWeight: FontWeight.w500,
                                              height: 1.3
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20,),

                                if(esMovil)...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.schedule, color: Color(0xFF222B6F), size: 22),
                                                SizedBox(width: 8),
                                                Text(
                                                  "HORARIO",
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B6F)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLineaDetalle("Lunes: 9:00 - 19:00"),
                                            _buildLineaDetalle("Martes: 9:00 - 19:00"),
                                            _buildLineaDetalle("Miércoles: 9:00 - 19:00"),
                                            _buildLineaDetalle("Jueves: 9:00 - 19:00"),
                                            _buildLineaDetalle("Viernes: 9:00 - 19:00"),
                                            _buildLineaDetalle("Sábado: Cerrado", isCerrado: true),
                                            _buildLineaDetalle("Domingo: Cerrado", isCerrado: true),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.phone, color: Color(0xFF222B6F), size: 22),
                                                SizedBox(width: 8),
                                                Text(
                                                  "CONTACTO",
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B6F)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLineaDetalle("639 639 401"),
                                            _buildLineaDetalle("955 912 237"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ]else ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.schedule, color: Color(0xFF222B6F), size: 22),
                                                SizedBox(width: 8),
                                                Text(
                                                  "HORARIO",
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B6F)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLineaDetalle("Lunes: 9:00 - 19:00"),
                                            _buildLineaDetalle("Martes: 9:00 - 19:00"),
                                            _buildLineaDetalle("Miércoles: 9:00 - 19:00"),
                                            _buildLineaDetalle("Jueves: 9:00 - 19:00"),
                                            _buildLineaDetalle("Viernes: 9:00 - 19:00"),
                                            _buildLineaDetalle("Sábado: Cerrado", isCerrado: true),
                                            _buildLineaDetalle("Domingo: Cerrado", isCerrado: true),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.phone, color: Color(0xFF222B6F), size: 22),
                                                SizedBox(width: 8),
                                                Text(
                                                  "CONTACTO",
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B6F)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLineaDetalle("639 639 401"),
                                            _buildLineaDetalle("955 912 237"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                SizedBox(height: 20,),
                                const Row(
                                  children: [
                                    Icon(Icons.location_on, color: Color(0xFF222B6F), size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "DÓNDE ESTAMOS",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF222B6F)),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: _coordenadasTaller,
                                        initialZoom: 15.0,
                                        maxZoom: 18.0,
                                        minZoom: 5.0,
                                      ),
                                      children: [

                                        TileLayer(
                                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'com.example.tu_app',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _coordenadasTaller,
                                              width: 40,
                                              height: 40,
                                              child: const Icon(
                                                Icons.location_pin,
                                                color: Colors.red,
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: Text(_direccionTaller, style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                )
              )
          );
        }
        ),
    );
  }
}