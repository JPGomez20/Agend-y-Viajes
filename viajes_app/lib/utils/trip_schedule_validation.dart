String? validarHorarioSolicitud({
  required DateTime? salida,
  required DateTime? retorno,
  required bool requiereRetorno,
  required bool retornoIncompleto,
  required DateTime ahora,
}) {
  if (salida == null) return 'Selecciona la fecha y hora de salida';
  if (salida.isBefore(ahora)) return 'La salida debe ser en el futuro';
  if (retornoIncompleto) {
    return 'Completa la fecha y hora de retorno';
  }
  if (requiereRetorno && retorno == null) {
    return 'Selecciona la fecha y hora de retorno';
  }
  if (retorno != null && !retorno.isAfter(salida)) {
    return 'El retorno debe ser posterior a la salida';
  }
  return null;
}
