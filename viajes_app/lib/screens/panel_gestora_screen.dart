import 'package:flutter/material.dart';
import '../main.dart';

class PanelGestoraScreen extends StatefulWidget {
  const PanelGestoraScreen({super.key});
  @override
  State<PanelGestoraScreen> createState() => _PanelGestoraScreenState();
}

class _PanelGestoraScreenState extends State<PanelGestoraScreen> with SingleTickerProviderStateMixin {
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
      final res = await supabase.from('viajes').select('*, centros(nombre)').order('fecha_salida');
      setState(() { viajes = List<Map<String, dynamic>>.from(res); cargando = false; });
    } catch (_) {
      setState(() {
        viajes = [
          {'id': '1', 'centros': {'nombre': 'CENTRO 1'}, 'fecha_salida': '2026-11-24', 'hora_salida': '05:00', 'punto_recojo': 'Oficina central -> CENTRO 1', 'estado': 'aprobado', 'motivo': 'CENTRO: Supervisión', 'conductor': '', 'placa': ''},
          {'id': '2', 'centros': {'nombre': 'CENTRO 2'}, 'fecha_salida': '2026-11-24', 'hora_salida': '06:00', 'punto_recojo': 'Mi casa -> CENTRO 2', 'estado': 'pendiente', 'motivo': 'CENTRO: Visita', 'conductor': '', 'placa': ''},
          {'id': '3', 'centros': null, 'fecha_salida': '2026-11-24', 'hora_salida': '09:00', 'punto_recojo': 'Oficina central -> Aeropuerto', 'estado': 'aprobado', 'motivo': 'TAXI A-B: Recoger cliente | Solo ida: true', 'conductor': 'Carlos', 'placa': 'ABC-123'},
          {'id': '4', 'centros': null, 'fecha_salida': '2026-11-25', 'hora_salida': '14:00', 'punto_recojo': 'Aeropuerto -> Oficina central', 'estado': 'completado', 'motivo': 'TAXI A-B: Llevar documentos', 'conductor': 'Carlos', 'placa': 'ABC-123'},
          {'id': '5', 'centros': {'nombre': 'CENTRO 1'}, 'fecha_salida': '2026-11-25', 'hora_salida': '05:30', 'punto_recojo': 'Oficina central -> CENTRO 1', 'estado': 'completado', 'motivo': 'CENTRO: Auditoría', 'conductor': 'Carlos', 'placa': 'ABC-123'},
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

  final res = await showDialog<Map<String, String>?>(context: context, builder: (_) => AlertDialog(
    title: Text(esTaxiAB ? 'Asignar Taxi A-B' : 'Asignar Taxi a Centro'),
    content: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: conductorC, decoration: const InputDecoration(labelText: 'Conductor')),
        const SizedBox(height: 10),
        TextField(controller: placaC, decoration: const InputDecoration(labelText: 'Placa')),
        const SizedBox(height: 10),
        TextField(controller: precioC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio S/ (lo que cobra el proveedor)', prefixText: 'S/ ')),
        const SizedBox(height: 8),
        const Text('El precio puede variar por punto de salida, hora, espera, etc. Pon el precio real que te pasó el proveedor.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ElevatedButton(onPressed: () => Navigator.pop(context, {'conductor': conductorC.text, 'placa': placaC.text, 'precio': precioC.text}), child: const Text('Guardar')),
    ],
  ));

  if (res != null) {
    try {
      await supabase.from('viajes').update({
        'conductor': res['conductor'],
        'placa': res['placa'],
        'precio': double.tryParse(res['precio'] ?? '0') ?? 0,
      }).eq('id', id);
    } catch (_) {}
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

  Widget _lista(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay viajes en esta categoría 🎉')));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final v = lista[i];
        final taxi = esTaxi(v);
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: taxi ? Colors.orange.shade100 : Colors.green.shade100, child: Icon(taxi ? Icons.local_taxi : Icons.grass, color: taxi ? Colors.orange : Colors.green)),
            title: Text(taxi ? v['punto_recojo'] : '${v['centros']?['nombre'] ?? 'CENTRO'} - ${v['fecha_salida']}'),
            subtitle: Text('Hora: ${v['hora_salida']}\n${v['motivo'] ?? ''}\nEstado: ${v['estado']} - Taxi: ${v['conductor'] ?? ''} ${v['placa'] ?? ''}'),
            isThreeLine: true,
           trailing: v['estado'] == 'aprobado'
     ? IconButton(icon: const Icon(Icons.local_taxi), onPressed: () => asignarTaxi(v['id'].toString(), esTaxi(v)))
     : IconButton(icon: const Icon(Icons.edit), onPressed: () => asignarTaxi(v['id'].toString(), esTaxi(v))),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final centros = viajes.where(esCentro).toList();
    final taxis = viajes.where(esTaxi).toList();
    final pendientes = viajes.where((v) => v['estado'] == 'pendiente').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Gestora'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Todos'),
          Tab(text: '🌱 Centros'),
          Tab(text: '🚕 Taxi A-B'),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text('$pendientes', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)), const Text('Pendientes')])))),
              const SizedBox(width: 10),
              Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text('${centros.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)), const Text('Viajes Centro')])))),
              const SizedBox(width: 10),
              Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text('${taxis.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)), const Text('Taxi A-B')])))),
            ]),
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Liquidación Fin de Mes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('🌱 Centros'), Text('${centros.length} viajes')]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('🚕 Taxi A-B'), Text('${taxis.length} viajes')]),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('${viajes.length} viajes', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  const Text('Luego aquí ponemos el precio: Centro = precio fijo, Taxi A-B = según ruta.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 600,
              child: TabBarView(controller: _tabController, children: [
                _lista(viajes),
                _lista(centros),
                _lista(taxis),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}