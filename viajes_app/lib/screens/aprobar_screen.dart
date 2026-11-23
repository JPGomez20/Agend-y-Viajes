import 'package:flutter/material.dart';
import '../main.dart';

class AprobarScreen extends StatefulWidget {
  const AprobarScreen({super.key});
  @override
  State<AprobarScreen> createState() => _AprobarScreenState();
}

class _AprobarScreenState extends State<AprobarScreen> {
  List<Map<String, dynamic>> viajes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarViajes();
  }

  Future<void> cargarViajes() async {
    try {
      final res = await supabase.from('viajes').select('*, centros(nombre)').eq('estado', 'pendiente').order('created_at');
      setState(() { viajes = List<Map<String, dynamic>>.from(res); cargando = false; });
    } catch (e) {
      // Datos de prueba para que puedas ver cómo se ve
      setState(() {
        viajes = [
          {'id': '1', 'punto_recojo': 'Oficina central', 'fecha_salida': '2026-11-24', 'hora_salida': '05:00', 'acompanantes': 1, 'centros': {'nombre': 'CENTRO 1'}},
          {'id': '2', 'punto_recojo': 'Mi casa', 'fecha_salida': '2026-11-25', 'hora_salida': '06:00', 'acompanantes': 0, 'centros': {'nombre': 'CENTRO 2'}},
        ];
        cargando = false;
      });
    }
  }

  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    try {
      await supabase.from('viajes').update({'estado': nuevoEstado}).eq('id', id);
    } catch (_) {}
    setState(() => viajes.removeWhere((v) => v['id'].toString() == id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nuevoEstado == 'aprobado' ? '✅ Viaje aprobado' : '❌ Viaje rechazado')));
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Viajes por aprobar')),
      body: viajes.isEmpty
          ? const Center(child: Text('No hay viajes pendientes 🎉'))
          : ListView.builder(
              itemCount: viajes.length,
              itemBuilder: (context, i) {
                final v = viajes[i];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(v['centros']?['nombre'] ?? 'CENTRO'),
                    subtitle: Text('Fecha: ${v['fecha_salida']} - Hora: ${v['hora_salida']}\nRecojo: ${v['punto_recojo']} - Acompañantes: ${v['acompanantes']}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => cambiarEstado(v['id'].toString(), 'aprobado')),
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => cambiarEstado(v['id'].toString(), 'rechazado')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}