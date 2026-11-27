import 'package:flutter_test/flutter_test.dart';
import 'package:viajes_app/utils/trip_schedule_validation.dart';

void main() {
  final ahora = DateTime(2026, 11, 27, 8);

  test('rechaza una salida pasada', () {
    final error = validarHorarioSolicitud(
      salida: DateTime(2026, 11, 27, 7, 59),
      retorno: null,
      requiereRetorno: false,
      retornoIncompleto: false,
      ahora: ahora,
    );

    expect(error, 'La salida debe ser en el futuro');
  });

  test('exige retorno para viajes de taxi de ida y vuelta', () {
    final error = validarHorarioSolicitud(
      salida: DateTime(2026, 11, 28, 8),
      retorno: null,
      requiereRetorno: true,
      retornoIncompleto: false,
      ahora: ahora,
    );

    expect(error, 'Selecciona la fecha y hora de retorno');
  });

  test('rechaza retorno incompleto o anterior a la salida', () {
    final incompleto = validarHorarioSolicitud(
      salida: DateTime(2026, 11, 28, 8),
      retorno: null,
      requiereRetorno: false,
      retornoIncompleto: true,
      ahora: ahora,
    );
    final anterior = validarHorarioSolicitud(
      salida: DateTime(2026, 11, 28, 8),
      retorno: DateTime(2026, 11, 28, 7, 59),
      requiereRetorno: false,
      retornoIncompleto: false,
      ahora: ahora,
    );

    expect(incompleto, 'Completa la fecha y hora de retorno');
    expect(anterior, 'El retorno debe ser posterior a la salida');
  });

  test('acepta salida futura sin retorno y retorno posterior', () {
    final salidaFutura = validarHorarioSolicitud(
      salida: DateTime(2026, 11, 28, 8),
      retorno: null,
      requiereRetorno: false,
      retornoIncompleto: false,
      ahora: ahora,
    );
    final idaYVuelta = validarHorarioSolicitud(
      salida: DateTime(2026, 11, 28, 8),
      retorno: DateTime(2026, 11, 28, 9),
      requiereRetorno: true,
      retornoIncompleto: false,
      ahora: ahora,
    );

    expect(salidaFutura, isNull);
    expect(idaYVuelta, isNull);
  });
}
