import 'package:flutter/material.dart';
import '../main.dart';

class PedirViajeScreen extends StatefulWidget {
  final String nombre;
  const PedirViajeScreen({super.key, required this.nombre});
  @override
  State<PedirViajeScreen> createState() => _PedirViajeScreenState();
}

class _PedirViajeScreenState extends State<PedirViajeScreen> {
  String tipoViaje = 'centro'; // centro o taxi
  String? centroId;
  String puntoRecojo = 'Oficina central';
  final _origenController = TextEditingController(text: 'Oficina central');
  final _destinoController = TextEditingController();
  final _motivoController = TextEditingController();
  DateTime? fechaSalida;
  TimeOfDay? horaSalida;
  DateTime? fechaRetorno;
  TimeOfDay? horaRetorno;
  bool soloIda = false;
  int acompanantes = 0;
  List<Map<String, dynamic>> centros = [];

  @override
  void initState() {
    super.initState();
    cargarCentros();
  }

  Future<void> cargarCentros() async {
    try {
      final res = await supabase.from('centros').select().order('nombre');
      setState(() => centros = List<Map<String, dynamic>>.from(res));
    } catch (_) {
      setState(() => centros = [
        {'id': '1', 'nombre': 'CENTRO 1'},
        {'id': '2', 'nombre': 'CENTRO 2'},
      ]);
    }
  }

  Future<void> seleccionarFecha(bool esSalida) async {
    final f = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
    if (f != null) {
      setState(() { if (esSalida) {
      fechaSalida = f;
    } else {
      fechaRetorno = f;
    } });
    }
  }

  Future<void> seleccionarHora(bool esSalida) async {
    final h = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 5, minute: 0));
    if (h != null) {
      setState(() { if (esSalida) {
      horaSalida = h;
    } else {
      horaRetorno = h;
    } });
    }
  }

  Future<void> enviar() async {
    if (fechaSalida == null || horaSalida == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta fecha y hora')));
      return;
    }
    if (tipoViaje == 'centro' && centroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elige un centro')));
      return;
    }
    if (tipoViaje == 'taxi' && _destinoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe el destino (Punto B)')));
      return;
    }

    final destinoFinal = tipoViaje == 'centro'
        ? centros.firstWhere((c) => c['id'].toString() == centroId)['nombre']
        : _destinoController.text;
    final origenFinal = tipoViaje == 'centro' ? puntoRecojo : _origenController.text;

    try {
      await supabase.from('viajes').insert({
        'centro_id': tipoViaje == 'centro' ? centroId : null,
        'fecha_salida': fechaSalida!.toIso8601String().split('T')[0],
        'hora_salida': '${horaSalida!.hour}:${horaSalida!.minute}:00',
        'fecha_retorno': fechaRetorno?.toIso8601String().split('T')[0],
        'hora_retorno': horaRetorno != null ? '${horaRetorno!.hour}:${horaRetorno!.minute}:00' : null,
        'punto_recojo': '$origenFinal -> $destinoFinal',
        'acompanantes': acompanantes,
        'estado': 'pendiente',
        // Guardamos el tipo en motivo por ahora para que la gestora lo vea
        'motivo': tipoViaje == 'centro' ? 'CENTRO: ${_motivoController.text}' : 'TAXI A-B: ${_motivoController.text} | Solo ida: $soloIda',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Solicitud enviada')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guardado en modo prueba: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedir Viaje')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Qué tipo de viaje necesitas?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tipoCard('centro', '🌱 Centro', 'Ir a cultivo')),
              const SizedBox(width: 10),
              Expanded(child: _tipoCard('taxi', '🚕 Taxi A-B', 'Traslado')),
            ]),
            const SizedBox(height: 20),
            if (tipoViaje == 'centro') ...[
              const Text('¿A qué centro vas?', style: TextStyle(fontWeight: FontWeight.bold)),
              ...centros.map((c) => RadioListTile<String>(title: Text(c['nombre']), value: c['id'].toString(), groupValue: centroId, onChanged: (v) => setState(() => centroId = v))),
              const Text('Punto de recojo', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(isExpanded: true, value: puntoRecojo, items: ['Oficina central', 'Mi casa', 'Aeropuerto', 'Otro punto'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => puntoRecojo = v!)),
            ] else ...[
              TextField(controller: _origenController, decoration: const InputDecoration(labelText: 'Punto A - ¿Desde dónde te recogemos?', prefixIcon: Icon(Icons.my_location))),
              const SizedBox(height: 12),
              TextField(controller: _destinoController, decoration: const InputDecoration(labelText: 'Punto B - ¿Hasta dónde vas?', prefixIcon: Icon(Icons.location_on))),
              const SizedBox(height: 12),
              SwitchListTile(title: const Text('Solo ida (sin retorno)'), value: soloIda, onChanged: (v) => setState(() => soloIda = v)),
            ],
            const SizedBox(height: 12),
            TextField(controller: _motivoController, decoration: const InputDecoration(labelText: 'Motivo del viaje (ej: Reunión, recojo, etc.)')),
            const SizedBox(height: 16),
            ListTile(title: const Text('Fecha salida'), subtitle: Text(fechaSalida == null ? 'Seleccionar' : '${fechaSalida!.day}/${fechaSalida!.month}'), trailing: const Icon(Icons.calendar_today), onTap: () => seleccionarFecha(true)),
            ListTile(title: const Text('Hora salida'), subtitle: Text(horaSalida == null ? 'Seleccionar' : horaSalida!.format(context)), trailing: const Icon(Icons.access_time), onTap: () => seleccionarHora(true)),
            if (!soloIda) ...[
              ListTile(title: const Text('Fecha retorno'), subtitle: Text(fechaRetorno == null ? 'Seleccionar' : '${fechaRetorno!.day}/${fechaRetorno!.month}'), trailing: const Icon(Icons.calendar_today), onTap: () => seleccionarFecha(false)),
              ListTile(title: const Text('Hora retorno'), subtitle: Text(horaRetorno == null ? 'Seleccionar' : horaRetorno!.format(context)), trailing: const Icon(Icons.access_time), onTap: () => seleccionarHora(false)),
            ],
            Row(children: [const Text('¿Van más personas? '), IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() { if (acompanantes > 0) acompanantes--; })), Text('$acompanantes'), IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => acompanantes++))]),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: enviar, child: const Text('Solicitar Viaje')),
          ],
        ),
      ),
    );
  }

  Widget _tipoCard(String valor, String titulo, String subtitulo) {
    final activo = tipoViaje == valor;
    return GestureDetector(
      onTap: () => setState(() => tipoViaje = valor),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF1B7A3D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: activo ? const Color(0xFF1B7A3D) : Colors.grey.shade300),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: activo ? Colors.white : Colors.black)),
          Text(subtitulo, style: TextStyle(color: activo ? Colors.white70 : Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }
}

