import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/trip_schedule_validation.dart';

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
  bool cargandoCentros = true;
  bool enviando = false;
  String? errorCentros;
  final _otroPuntoController = TextEditingController();
  final _direccionCasaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarCentros();
  }

  Future<void> cargarCentros() async {
    try {
      final res = await supabase.from('centros').select().order('nombre');
      if (!mounted) return;
      setState(() {
        centros = List<Map<String, dynamic>>.from(res);
        errorCentros = null;
        cargandoCentros = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error al cargar centros: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        errorCentros = 'No se pudieron cargar los centros.';
        cargandoCentros = false;
      });
    }
  }

  Future<void> reintentarCargaCentros() async {
    setState(() {
      cargandoCentros = true;
      errorCentros = null;
    });
    await cargarCentros();
  }

  Future<void> seleccionarFecha(bool esSalida) async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final primeraFecha = esSalida
        ? hoy
        : fechaSalida == null
            ? hoy
            : DateUtils.dateOnly(fechaSalida!);
    final ultimaFecha = hoy.add(const Duration(days: 90));
    final fechaSugerida = esSalida
        ? fechaSalida ?? hoy.add(const Duration(days: 1))
        : fechaRetorno ?? fechaSalida ?? hoy.add(const Duration(days: 1));
    final fechaInicial = fechaSugerida.isBefore(primeraFecha)
        ? primeraFecha
        : fechaSugerida.isAfter(ultimaFecha)
            ? ultimaFecha
            : fechaSugerida;
    final f = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(fechaInicial),
      firstDate: primeraFecha,
      lastDate: ultimaFecha,
    );
    if (f != null && mounted) {
      setState(() {
        if (esSalida) {
          fechaSalida = f;
          if (fechaRetorno != null && fechaRetorno!.isBefore(f)) {
            fechaRetorno = null;
            horaRetorno = null;
          }
        } else {
          fechaRetorno = f;
        }
      });
    }
  }

  Future<void> seleccionarHora(bool esSalida) async {
    final h = await showTimePicker(
      context: context,
      initialTime: esSalida
          ? horaSalida ?? const TimeOfDay(hour: 5, minute: 0)
          : horaRetorno ?? const TimeOfDay(hour: 5, minute: 0),
    );
    if (h != null && mounted) {
      setState(() {
        if (esSalida) {
          horaSalida = h;
        } else {
          horaRetorno = h;
        }
      });
    }
  }

  Future<void> enviar() async {
    if (enviando) return;
    final origenEsOtro = tipoViaje == 'centro' && puntoRecojo == 'Otro punto';
    final origenFinal = tipoViaje == 'centro'
        ? origenEsOtro
            ? _otroPuntoController.text.trim()
            : puntoRecojo
        : _origenController.text.trim();
    final destinoIngresado = _destinoController.text.trim();

    if (tipoViaje == 'taxi' && origenFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el punto de recojo (Punto A)')),
      );
      return;
    }
    if (origenEsOtro && origenFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el punto de recojo')),
      );
      return;
    }
    if (tipoViaje == 'centro' &&
        puntoRecojo == 'Mi casa' &&
        _direccionCasaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la dirección de tu casa')),
      );
      return;
    }
    if (tipoViaje == 'taxi' && destinoIngresado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el destino (Punto B)')),
      );
      return;
    }
    if (tipoViaje == 'centro' &&
        (centroId == null ||
            !centros.any((c) => c['id'].toString() == centroId))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Elige un centro')));
      return;
    }

    final salida = fechaSalida == null || horaSalida == null
        ? null
        : DateTime(
            fechaSalida!.year,
            fechaSalida!.month,
            fechaSalida!.day,
            horaSalida!.hour,
            horaSalida!.minute,
          );
    final retorno = fechaRetorno == null || horaRetorno == null
        ? null
        : DateTime(
            fechaRetorno!.year,
            fechaRetorno!.month,
            fechaRetorno!.day,
            horaRetorno!.hour,
            horaRetorno!.minute,
          );
    final retornoIncompleto =
        (fechaRetorno == null) != (horaRetorno == null);
    final requiereRetorno = tipoViaje == 'taxi' && !soloIda;
    final errorHorario = validarHorarioSolicitud(
      salida: salida,
      retorno: retorno,
      requiereRetorno: requiereRetorno,
      retornoIncompleto: retornoIncompleto,
      ahora: DateTime.now(),
    );
    if (errorHorario != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorHorario)));
      return;
    }

    final destinoFinal = tipoViaje == 'centro'
        ? centros
            .firstWhere((c) => c['id'].toString() == centroId)['nombre']
            .toString()
        : destinoIngresado;
    final origenDeCentro = switch (puntoRecojo) {
      'Mi casa' => 'Mi casa: ${_direccionCasaController.text.trim()}',
      'Otro punto' => _otroPuntoController.text.trim(),
      _ => puntoRecojo,
    };
    final origenParaSolicitud =
        tipoViaje == 'centro' ? origenDeCentro : origenFinal;

    setState(() => enviando = true);
    try {
      await supabase.from('viajes').insert({
        'centro_id': tipoViaje == 'centro' ? centroId : null,
        'fecha_salida': fechaSalida!.toIso8601String().split('T')[0],
        'hora_salida':
            '${horaSalida!.hour.toString().padLeft(2, '0')}:${horaSalida!.minute.toString().padLeft(2, '0')}:00',
        'fecha_retorno': soloIda
            ? null
            : fechaRetorno?.toIso8601String().split('T')[0],
        'hora_retorno': soloIda
            ? null
            : horaRetorno != null
                ? '${horaRetorno!.hour.toString().padLeft(2, '0')}:${horaRetorno!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'punto_recojo': '$origenParaSolicitud -> $destinoFinal',
        'acompanantes': acompanantes,
        'estado': 'pendiente',
        'motivo': tipoViaje == 'centro'
            ? 'CENTRO: ${_motivoController.text.trim()}'
            : 'TAXI A-B: ${_motivoController.text.trim()} | Solo ida: $soloIda',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Solicitud enviada')));
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint('Error al enviar solicitud: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo enviar la solicitud. Verifica tu conexión e inténtalo nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    _motivoController.dispose();
    _otroPuntoController.dispose();
    _direccionCasaController.dispose();
    super.dispose();
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
            const Text(
              '¿Qué tipo de viaje necesitas?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _tipoCard('centro', 'Centro', 'Ir a cultivo')),
                const SizedBox(width: 10),
                Expanded(child: _tipoCard('taxi', 'Taxi A-B', 'Traslado')),
              ],
            ),
            const SizedBox(height: 20),
            if (tipoViaje == 'centro') ...[
              const Text(
                '¿A qué centro vas?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (cargandoCentros)
                const Center(child: CircularProgressIndicator())
              else if (errorCentros != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errorCentros!),
                    TextButton(
                      onPressed: reintentarCargaCentros,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              else if (centros.isEmpty)
                const Text('No hay centros disponibles.')
              else
                ...centros.map(
                  (c) => RadioListTile<String>(
                    title: Text(c['nombre'].toString()),
                    value: c['id'].toString(),
                    groupValue: centroId,
                    onChanged: (v) => setState(() => centroId = v),
                  ),
                ),
              const Text(
                'Punto de recojo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                isExpanded: true,
                value: puntoRecojo,
                items:
                    ['Oficina central', 'Mi casa', 'Aeropuerto', 'Otro punto']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => puntoRecojo = v);
                },
              ),
              if (puntoRecojo == 'Otro punto')
                TextField(
                  controller: _otroPuntoController,
                  decoration: const InputDecoration(
                    labelText: 'Especifica el punto de recojo',
                  ),
                ),
              if (puntoRecojo == 'Mi casa')
                TextField(
                  controller: _direccionCasaController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Dirección de casa',
                    hintText: 'Calle, número y referencia',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
            ] else ...[
              TextField(
                controller: _origenController,
                decoration: const InputDecoration(
                  labelText: 'Punto A - ¿Desde dónde te recogemos?',
                  prefixIcon: Icon(Icons.my_location),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _destinoController,
                decoration: const InputDecoration(
                  labelText: 'Punto B - ¿Hasta dónde vas?',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Solo ida (sin retorno)'),
                value: soloIda,
                onChanged: (v) => setState(() {
                  soloIda = v;
                  if (v) {
                    fechaRetorno = null;
                    horaRetorno = null;
                  }
                }),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo del viaje (ej: Reunión, recojo, etc.)',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Fecha salida'),
              subtitle: Text(
                fechaSalida == null
                    ? 'Seleccionar'
                    : '${fechaSalida!.day}/${fechaSalida!.month}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => seleccionarFecha(true),
            ),
            ListTile(
              title: const Text('Hora salida'),
              subtitle: Text(
                horaSalida == null
                    ? 'Seleccionar'
                    : horaSalida!.format(context),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () => seleccionarHora(true),
            ),
            if (tipoViaje != 'taxi' || !soloIda) ...[
              ListTile(
                title: const Text('Fecha retorno'),
                subtitle: Text(
                  fechaRetorno == null
                      ? 'Seleccionar'
                      : '${fechaRetorno!.day}/${fechaRetorno!.month}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => seleccionarFecha(false),
              ),
              ListTile(
                title: const Text('Hora retorno'),
                subtitle: Text(
                  horaRetorno == null
                      ? 'Seleccionar'
                      : horaRetorno!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => seleccionarHora(false),
              ),
            ],
            Row(
              children: [
                const Text('¿Van más personas? '),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() {
                    if (acompanantes > 0) acompanantes--;
                  }),
                ),
                Text('$acompanantes'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => acompanantes++),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: enviando || cargandoCentros && tipoViaje == 'centro'
                  ? null
                  : enviar,
              child: enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Solicitar Viaje'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoCard(String valor, String titulo, String subtitulo) {
    final activo = tipoViaje == valor;
    return Semantics(
      button: true,
      selected: activo,
      child: GestureDetector(
      onTap: () => setState(() {
        tipoViaje = valor;
        if (valor != 'taxi') soloIda = false;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF1B7A3D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activo ? const Color(0xFF1B7A3D) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: activo ? Colors.white : Colors.black,
              ),
            ),
            Text(
              subtitulo,
              style: TextStyle(
                color: activo ? Colors.white70 : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
