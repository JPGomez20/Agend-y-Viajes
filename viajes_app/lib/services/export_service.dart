import 'dart:typed_data';
import 'package:excel/excel.dart';
// Para web (Edge) necesitamos esto para descargar
import 'dart:html' as html;

class ExportService {
  static Future<void> exportarLiquidacion({
    required List<Map<String, dynamic>> viajes,
    required bool Function(Map v) esTaxi,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Liquidación'];

    // Título
    sheet.appendRow([TextCellValue('LIQUIDACIÓN FIN DE MES - PROVEEDOR TAXI')]);
    sheet.appendRow([TextCellValue('Fecha de exportación: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}')]);
    sheet.appendRow([]); // fila vacía

    // Cabecera
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Tipo'),
      TextCellValue('Ruta / Centro'),
      TextCellValue('Punto Recojo'),
      TextCellValue('Estado'),
      TextCellValue('Conductor'),
      TextCellValue('Placa'),
      TextCellValue('Precio S/'),
      TextCellValue('Motivo'),
    ]);

    double totalCentros = 0;
    double totalTaxis = 0;

    for (var v in viajes) {
      final esTaxiAB = esTaxi(v);
      final precio = double.tryParse(v['precio']?.toString() ?? '0') ?? 0;
      if (esTaxiAB) {
        totalTaxis += precio;
      } else {
        totalCentros += precio;
      }

      final tipo = esTaxiAB ? 'TAXI A-B' : 'CENTRO';
      final ruta = esTaxiAB ? v['punto_recojo'] ?? '' : (v['centros']?['nombre'] ?? 'CENTRO');

      sheet.appendRow([
        TextCellValue(v['fecha_salida']?.toString() ?? ''),
        TextCellValue(tipo),
        TextCellValue(ruta.toString()),
        TextCellValue(v['punto_recojo']?.toString() ?? ''),
        TextCellValue(v['estado']?.toString() ?? ''),
        TextCellValue(v['conductor']?.toString() ?? ''),
        TextCellValue(v['placa']?.toString() ?? ''),
        DoubleCellValue(precio),
        TextCellValue(v['motivo']?.toString() ?? ''),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('RESUMEN')]);
    sheet.appendRow([TextCellValue('Total Centros'), DoubleCellValue(totalCentros)]);
    sheet.appendRow([TextCellValue('Total Taxi A-B'), DoubleCellValue(totalTaxis)]);
    sheet.appendRow([TextCellValue('TOTAL A PAGAR'), DoubleCellValue(totalCentros + totalTaxis)]);

    // Guardar y descargar en Edge / Chrome
    final bytes = excel.save();
    if (bytes != null) {
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'liquidacion_${DateTime.now().month}_${DateTime.now().year}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}



