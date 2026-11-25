import 'package:flutter/material.dart';
import 'pedir_viaje_screen.dart';
import 'aprobar_screen.dart';
import 'panel_gestora_screen.dart';

class HomeScreen extends StatelessWidget {
  final String nombre;
  const HomeScreen({super.key, required this.nombre});

  Widget _opcion(BuildContext context, {required IconData icono, required String titulo, required String subtitulo, required Color color, required Widget destino}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icono, color: color, size: 28)),
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
      appBar: AppBar(title: Text('Hola, $nombre')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _opcion(context, icono: Icons.add_location_alt, titulo: 'Pedir Viaje', subtitulo: 'Solicita taxi a Centro 1 o Centro 2', color: const Color(0xFF1B7A3D), destino: PedirViajeScreen(nombre: nombre)),
            const SizedBox(height: 12),
            _opcion(context, icono: Icons.check_circle_outline, titulo: 'Aprobar Viajes', subtitulo: 'Para jefes • 2 pendientes', color: const Color(0xFFF59E0B), destino: const AprobarScreen()),
            const SizedBox(height: 12),
            _opcion(context, icono: Icons.dashboard_outlined, titulo: 'Panel Gestora', subtitulo: 'Viajes de hoy, taxis y liquidación', color: Colors.blue, destino: const PanelGestoraScreen()),
          ],
        ),
      ),
    );
  }
}

