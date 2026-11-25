import 'package:flutter/material.dart';
import 'pedir_viaje_screen.dart';
import 'aprobar_screen.dart';
import 'panel_gestora_screen.dart';
import 'mis_viajes_taxista_screen.dart';

class HomeScreen extends StatelessWidget {
  final String nombre;
  final String rol; // trabajador, jefe, gestora, taxista
  const HomeScreen({super.key, required this.nombre, required this.rol});

  String get tituloRol {
    if (rol == 'gestora') return 'Gestora';
    if (rol == 'jefe') return 'Jefe';
    if (rol == 'taxista') return 'Conductor';
    return 'Trabajador';
  }

  Widget _opcion(BuildContext context, {required IconData icono, required String titulo, required String subtitulo, required Color color, required Widget destino}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icono, color: color, size: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 13))])),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hola, $nombre • $tituloRol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SI ES CONDUCTOR, SOLO VE SUS VIAJES
            if (rol == 'taxista')
              _opcion(context, icono: Icons.local_taxi, titulo: 'Mis Viajes Asignados', subtitulo: 'Viajes que te asignó la gestora', color: Colors.orange, destino: MisViajesTaxistaScreen(nombreConductor: nombre)),
            if (rol == 'taxista') const SizedBox(height: 12),

            // SI NO ES CONDUCTOR, VE LO NORMAL
            if (rol != 'taxista')
              _opcion(context, icono: Icons.add_location_alt, titulo: 'Pedir Viaje', subtitulo: 'Solicita taxi a Centro o A-B', color: const Color(0xFF1B7A3D), destino: PedirViajeScreen(nombre: nombre)),
            if (rol != 'taxista') const SizedBox(height: 12),

            if (rol == 'jefe' || rol == 'gestora')
              _opcion(context, icono: Icons.check_circle_outline, titulo: 'Aprobar Viajes', subtitulo: 'Aprueba los viajes de tu equipo', color: const Color(0xFFF59E0B), destino: const AprobarScreen()),
            if (rol == 'jefe' || rol == 'gestora') const SizedBox(height: 12),

            if (rol == 'gestora')
              _opcion(context, icono: Icons.dashboard_outlined, titulo: 'Panel Gestora', subtitulo: 'Viajes, taxis, precios y liquidación', color: Colors.blue, destino: const PanelGestoraScreen()),

            const SizedBox(height: 20),
            if (rol == 'trabajador')
              const Text('Como trabajador solo puedes pedir viajes. No ves aprobaciones ni precios.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            if (rol == 'jefe')
              const Text('Como jefe puedes pedir y aprobar viajes, pero no ves la liquidación.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            if (rol == 'taxista')
              const Text('Solo ves tus viajes asignados. No ves precios ni liquidación.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
