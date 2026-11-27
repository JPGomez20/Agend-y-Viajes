import 'package:flutter/material.dart';

import '../main.dart';
import '../services/export_service.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> avisarCarlosPorWhatsApp({
  required String origen,
  required String destino,
  required String fecha,
  required String hora,
  required String pasajero,
}) async {
  const telefonoCarlos = '51948786732'; // 948786732 provisional
  final mensaje = 'Hola Carlos, te asignaron un viaje \n\n'
      'De: $origen\n'
      'A: $destino\n'
      'Fecha: $fecha - $hora\n'
      'Pasajero: $pasajero\n\n'
      'Por favor confirma en la app Mar Andino.';
  final url = Uri.parse('https://wa.me/$telefonoCarlos?text=${Uri.encodeComponent(mensaje)}');
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

class PanelGestoraScreen extends StatefulWidget {
  const PanelGestoraScreen({super.key});
  @override
  State<PanelGestoraScreen> createState() => _PanelGestoraScreenState();
}

class _PanelGestoraScreenState extends State<PanelGestoraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> viajes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    cargarViajes();
  }

  Future<void> cargarViajes() async {
    try {
      final res = await supabase
          .from('viajes')
          .select('*, centros(nombre)')
          .order('fecha_salida');
      setState(() {
        viajes = List<Map<String, dynamic>>.from(res);
        cargando = false;
      });
    } catch (_) {
      setState(() {
        viajes = [
          {
            'id': '1',
            'centros': {'nombre': 'CENTRO 1'},
            'fecha_salida': '2026-11-24',
            'hora_salida': '05:00',
            'punto_recojo': 'Oficina central -> CENTRO 1',
            'estado': 'aprobado',
            'motivo': 'CENTRO: Supervisión',
            'conductor': '',
            'placa': '',
            'precio': 0,
          },
          {
            'id': '2',
            'centros': {'nombre': 'CENTRO 2'},
            'fecha_salida': '2026-11-24',
            'hora_salida': '06:00',
            'punto_recojo': 'Mi casa -> CENTRO 2',
            'estado': 'pendiente',
            'motivo': 'CENTRO: Visita',
            'conductor': '',
            'placa': '',
            'precio': 0,
          },
          {
            'id': '3',
            'centros': null,
            'fecha_salida': '2026-11-24',
            'hora_salida': '09:00',
            'punto_recojo': 'Oficina central -> Aeropuerto',
            'estado': 'aprobado',
            'motivo': 'TAXI A-B: Recoger cliente | Solo ida: true',
            'conductor': 'Carlos',
            'placa': 'ABC-123',
            'precio': 80,
          },
          {
            'id': '4',
            'centros': null,
            'fecha_salida': '2026-11-25',
            'hora_salida': '14:00',
            'punto_recojo': 'Aeropuerto -> Oficina central',
            'estado': 'completado',
            'motivo': 'TAXI A-B: Llevar documentos',
            'conductor': 'Carlos',
            'placa': 'ABC-123',
            'precio': 90,
          },
          {
            'id': '5',
            'centros': {'nombre': 'CENTRO 1'},
            'fecha_salida': '2026-11-25',
            'hora_salida': '05:30',
            'punto_recojo': 'Oficina central -> CENTRO 1',
            'estado': 'completado',
            'motivo': 'CENTRO: Auditoría',
            'conductor': 'Carlos',
            'placa': 'ABC-123',
            'precio': 250,
          },
        ];
        cargando = false;
      });
    }
  }

  bool esTaxi(Map v) => (v['motivo'] ?? '').toString().contains('TAXI A-B');
  bool esCentro(Map v) => !esTaxi(v);

  Future<void> asignarTaxi(String id, bool esTaxiAB) async {
    final placaC = TextEditingController();
    final conductorC = TextEditingController();
    final precioC = TextEditingController();
    final res = await showDialog<Map<String, String>?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esTaxiAB ? 'Asignar Taxi A-B' : 'Asignar Taxi a Centro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: conductorC,
                decoration: const InputDecoration(labelText: 'Conductor'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: placaC,
                decoration: const InputDecoration(labelText: 'Placa'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: precioC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio S/',
                  prefixText: 'S/ ',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'El precio varía por origen, hora, espera, etc. Pon el precio real.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'conductor': conductorC.text,
              'placa': placaC.text,
              'precio': precioC.text,
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (res != null) {
      try {
        await supabase
            .from('viajes')
            .update({
              'conductor': res['conductor'],
              'placa': res['placa'],
              'precio': double.tryParse(res['precio'] ?? '0') ?? 0,
            })
            .eq('id', id);
      } catch (_) {}
      // WhatsApp a Carlos - solo si el conductor es Carlos
      final viajeActual = viajes.firstWhere((v) => v['id'].toString() == id, orElse: () => {});
      if ((res['conductor'] ?? '').toString().toLowerCase().contains('carlos')) {
        await avisarCarlosPorWhatsApp(
          origen: viajeActual['punto_recojo']?.toString() ?? 'Mar Andino',
          destino: viajeActual['centros']?['nombre']?.toString() ?? 'Destino',
          fecha: viajeActual['fecha_salida']?.toString() ?? '',
          hora: viajeActual['hora_salida']?.toString() ?? '',
          pasajero: viajeActual['motivo']?.toString() ?? '',
        );
      }
      setState(() {
        final i = viajes.indexWhere((v) => v['id'].toString() == id);
        if (i != -1) {
          viajes[i]['conductor'] = res['conductor'];
          viajes[i]['placa'] = res['placa'];
          viajes[i]['precio'] = double.tryParse(res['precio'] ?? '0') ?? 0;
        }
      });
    }
  }

  Widget _liquidacion() {
    double totalCentros = 0;
    for (var v in viajes.where(esCentro)) {
      totalCentros += double.tryParse(v['precio']?.toString() ?? '0') ?? 0;
    }
    double totalTaxis = 0;
    for (var v in viajes.where(esTaxi)) {
      totalTaxis += double.tryParse(v['precio']?.toString() ?? '0') ?? 0;
    }
    double totalGeneral = totalCentros + totalTaxis;

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liquidación Fin de Mes - Proveedor Taxi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Centros (${viajes.where(esCentro).length} viajes)'),
                Text('S/ ${totalCentros.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Taxi A-B (${viajes.where(esTaxi).length} viajes)'),
                Text('S/ ${totalTaxis.toStringAsFixed(0)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total a pagar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'S/ ${totalGeneral.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1B7A3D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Precio por viaje, puesto por la gestora. Varía por origen, hora, espera y retorno.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Exportar Liquidación a Excel'),
                onPressed: () async {
                  await ExportService.exportarLiquidacion(
                    viajes: viajes,
                    esTaxi: esTaxi,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Excel descargado')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No hay viajes en esta categoría'),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final v = lista[i];
        final taxi = esTaxi(v);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: taxi
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
              child: Icon(
                taxi ? Icons.local_taxi : Icons.grass,
                color: taxi ? Colors.orange : Colors.green,
              ),
            ),
            title: Text(
              taxi
                  ? v['punto_recojo']
                  : '${v['centros']?['nombre'] ?? 'CENTRO'} - ${v['fecha_salida']}',
            ),
            subtitle: Text(
              'Hora: ${v['hora_salida']}\n${v['motivo'] ?? ''}\nEstado: ${v['estado']} - Taxi: ${v['conductor'] ?? ''} ${v['placa'] ?? ''} - Precio: S/ ${v['precio'] ?? 0}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(
                v['estado'] == 'aprobado' ? Icons.local_taxi : Icons.edit,
              ),
              onPressed: () => asignarTaxi(v['id'].toString(), esTaxi(v)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final centros = viajes.where(esCentro).toList();
    final taxis = viajes.where(esTaxi).toList();
    final pendientes = viajes.where((v) => v['estado'] == 'pendiente').length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Gestora'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Centros'),
            Tab(text: 'Taxi A-B'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '$pendientes',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text('Pendientes'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '${centros.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text('Viajes Centro'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '${taxis.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text('Taxi A-B'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _liquidacion(),
            const SizedBox(height: 16),
            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tabController,
                children: [_lista(viajes), _lista(centros), _lista(taxis)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
