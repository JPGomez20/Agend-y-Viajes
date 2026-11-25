import 'package:flutter/material.dart';

import '../main.dart';

class MisViajesTaxistaScreen extends StatefulWidget {
  final String nombreConductor;
  const MisViajesTaxistaScreen({super.key, required this.nombreConductor});
  @override
  State<MisViajesTaxistaScreen> createState() => _MisViajesTaxistaScreenState();
}

class _MisViajesTaxistaScreenState extends State<MisViajesTaxistaScreen> {
  List<Map<String, dynamic>> viajes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarMisViajes();
  }

  Future<void> cargarMisViajes() async {
    try {
      final res = await supabase
          .from('viajes')
          .select('*, centros(nombre)')
          .eq('conductor', widget.nombreConductor)
          .order('fecha_salida');
      setState(() {
        viajes = List<Map<String, dynamic>>.from(res);
        cargando = false;
      });
    } catch (_) {
      setState(() {
        // Datos de prueba si no hay Supabase
        viajes = [
          {
            'id': '1',
            'centros': {'nombre': 'CENTRO 1'},
            'fecha_salida': '2026-11-26',
            'hora_salida': '05:00',
            'punto_recojo': 'Oficina central -> CENTRO 1',
            'estado': 'asignado',
            'motivo': 'CENTRO: Supervisión - Pasajero: Juan Perez',
            'conductor': widget.nombreConductor,
            'placa': 'ABC-123',
          },
          {
            'id': '3',
            'centros': null,
            'fecha_salida': '2026-11-26',
            'hora_salida': '09:00',
            'punto_recojo': 'Oficina central -> Aeropuerto',
            'estado': 'en_camino',
            'motivo': 'TAXI A-B: Recoger cliente - Pasajero: María Lopez',
            'conductor': widget.nombreConductor,
            'placa': 'ABC-123',
          },
        ];
        cargando = false;
      });
    }
  }

  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    try {
      await supabase
          .from('viajes')
          .update({'estado': nuevoEstado})
          .eq('id', id);
    } catch (_) {}
    setState(() {
      final i = viajes.indexWhere((v) => v['id'].toString() == id);
      if (i != -1) viajes[i]['estado'] = nuevoEstado;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Viaje marcado como $nuevoEstado')));
  }

  Color colorEstado(String estado) {
    if (estado == 'asignado') return Colors.orange;
    if (estado == 'en_camino') return Colors.blue;
    if (estado == 'completado') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pendientes = viajes
        .where((v) => v['estado'] != 'completado')
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text('Mis Viajes - ${widget.nombreConductor}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_taxi,
                      color: Colors.orange,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${widget.nombreConductor}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Tienes ${pendientes.length} viajes pendientes hoy',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mis Viajes Asignados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (viajes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No tienes viajes asignados todavía'),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: viajes.length,
                itemBuilder: (context, i) {
                  final v = viajes[i];
                  final esCentro = v['centros'] != null;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: esCentro
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  esCentro ? Icons.grass : Icons.local_taxi,
                                  color: esCentro
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  esCentro
                                      ? '${v['centros']?['nombre']} - ${v['fecha_salida']}'
                                      : v['punto_recojo'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorEstado(v['estado'])
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  v['estado'],
                                  style: TextStyle(
                                    color: colorEstado(v['estado']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Hora: ${v['hora_salida']}'),
                          Text('Recojo: ${v['punto_recojo']}'),
                          Text(v['motivo'] ?? ''),
                          Text('Placa: ${v['placa'] ?? ''}'),
                          const SizedBox(height: 10),
                          if (v['estado'] != 'completado')
                            Row(
                              children: [
                                if (v['estado'] == 'asignado' ||
                                    v['estado'] == 'aprobado')
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => cambiarEstado(
                                        v['id'].toString(),
                                        'en_camino',
                                      ),
                                      child: const Text('En camino'),
                                    ),
                                  ),
                                if (v['estado'] == 'asignado' ||
                                    v['estado'] == 'aprobado')
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () => cambiarEstado(
                                      v['id'].toString(),
                                      'completado',
                                    ),
                                    child: const Text('Completado'),
                                  ),
                                ),
                              ],
                            ),
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
