import 'package:flutter/material.dart';
import '../main.dart';

class MisViajesTrabajadorScreen extends StatefulWidget {
  final String nombre;
  const MisViajesTrabajadorScreen({super.key, required this.nombre});
  @override
  State<MisViajesTrabajadorScreen> createState() => _MisViajesTrabajadorScreenState();
}

class _MisViajesTrabajadorScreenState extends State<MisViajesTrabajadorScreen> {
  List<Map<String, dynamic>> viajes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarViajes();
  }

  Future<void> cargarViajes() async {
    try {
      final res = await supabase.from('viajes').select('*, centros(nombre)').order('fecha_salida', ascending: false);
      setState(() { viajes = List<Map<String, dynamic>>.from(res); cargando = false; });
    } catch (_) {
      setState(() {
        viajes = [
          {'id': '1', 'centros': {'nombre': 'CENTRO 1'}, 'fecha_salida': '2026-11-26', 'hora_salida': '05:00', 'punto_recojo': 'Oficina central -> CENTRO 1', 'estado': 'aceptado', 'motivo': 'CENTRO: Supervisión', 'conductor': 'Carlos', 'placa': 'ABC-123'},
          {'id': '2', 'centros': null, 'fecha_salida': '2026-11-26', 'hora_salida': '09:00', 'punto_recojo': 'Oficina central -> Aeropuerto', 'estado': 'en_camino', 'motivo': 'TAXI A-B: Recoger cliente', 'conductor': 'Carlos', 'placa': 'ABC-123'},
          {'id': '3', 'centros': {'nombre': 'CENTRO 2'}, 'fecha_salida': '2026-11-25', 'hora_salida': '06:00', 'punto_recojo': 'Mi casa -> CENTRO 2', 'estado': 'completado', 'motivo': 'CENTRO: Visita', 'conductor': 'Carlos', 'placa': 'ABC-123'},
          {'id': '4', 'centros': null, 'fecha_salida': '2026-11-25', 'hora_salida': '14:00', 'punto_recojo': 'Aeropuerto -> Oficina', 'estado': 'pendiente', 'motivo': 'TAXI A-B: Llevar documentos', 'conductor': '', 'placa': ''},
        ];
        cargando = false;
      });
    }
  }

  String textoEstado(String estado) {
    if (estado == 'pendiente') return 'Esperando aprobación del jefe';
    if (estado == 'aprobado') return 'Aprobado, esperando asignación';
    if (estado == 'asignado') return 'Asignado, esperando que el conductor acepte';
    if (estado == 'aceptado') return 'Aceptado por el conductor';
    if (estado == 'en_camino') return 'En camino, tu conductor ya viene';
    if (estado == 'completado') return 'Viaje completado';
    if (estado == 'rechazado') return 'Rechazado por el jefe';
    return estado;
  }

  Color colorEstado(String estado) {
    if (estado == 'pendiente' || estado == 'asignado' || estado == 'aprobado') return Colors.orange;
    if (estado == 'aceptado' || estado == 'en_camino') return Colors.blue;
    if (estado == 'completado') return Colors.green;
    if (estado == 'rechazado') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('Mis Viajes - ${widget.nombre}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Así va tu viaje:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Aquí ves si tu jefe lo aprobó y si tu conductor ya lo aceptó.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: viajes.length,
                itemBuilder: (context, i) {
                  final v = viajes[i];
                  final esCentro = v['centros'] != null;
                  final estado = v['estado'] ?? 'pendiente';
                  final tieneConductor = (v['conductor'] ?? '').toString().isNotEmpty;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: esCentro ? Colors.green.shade100 : Colors.orange.shade100, child: Icon(esCentro ? Icons.grass : Icons.local_taxi, color: esCentro ? Colors.green : Colors.orange)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(esCentro ? '${v['centros']?['nombre']} - ${v['fecha_salida']}' : '${v['punto_recojo']} - ${v['fecha_salida']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Hora: ${v['hora_salida']}'),
                          Text('Recojo: ${v['punto_recojo']}'),
                          Text('Motivo: ${v['motivo'] ?? ''}'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: colorEstado(estado).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Text(textoEstado(estado), style: TextStyle(color: colorEstado(estado), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          if (tieneConductor) ...[
                            const SizedBox(height: 8),
                            Text('Conductor: ${v['conductor']} - Placa: ${v['placa']}'),
                            if (estado == 'aceptado') const Text('Tu conductor ya aceptó y está en camino.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            if (estado == 'asignado') const Text('Tu conductor todavía no acepta. Espera un momento.', style: TextStyle(color: Colors.orange)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}