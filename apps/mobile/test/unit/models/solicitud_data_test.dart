import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/shared/widgets/solicitud_card.dart';

void main() {
  group('SolicitudData', () {
    final baseDate = DateTime(2026, 3, 15);

    // Not const because DateTime is not const-constructible
    final solicitud = SolicitudData(
      id: 'S-1',
      cuotaId: 'C-1',
      nroRecibo: 'TK-000001',
      tipo: 'Revisión de pago',
      descripcion: 'Pagué pero no se refleja',
      estado: SolicitudEstado.pendiente,
      fecha: baseDate,
      respuesta: null,
      propietarioId: 'P-1',
      propietarioNombre: 'Juan Pérez',
    );

    test('constructor asigna campos', () {
      expect(solicitud.id, 'S-1');
      expect(solicitud.cuotaId, 'C-1');
      expect(solicitud.nroRecibo, 'TK-000001');
      expect(solicitud.tipo, 'Revisión de pago');
      expect(solicitud.descripcion, 'Pagué pero no se refleja');
      expect(solicitud.estado, SolicitudEstado.pendiente);
      expect(solicitud.fecha, baseDate);
      expect(solicitud.respuesta, isNull);
      expect(solicitud.propietarioId, 'P-1');
      expect(solicitud.propietarioNombre, 'Juan Pérez');
    });

    test('todos los estados del enum', () {
      final pendiente = SolicitudData(
        id: '1', cuotaId: '', nroRecibo: '', tipo: '', descripcion: '',
        estado: SolicitudEstado.pendiente, fecha: baseDate,
      );
      final enRevision = SolicitudData(
        id: '2', cuotaId: '', nroRecibo: '', tipo: '', descripcion: '',
        estado: SolicitudEstado.enRevision, fecha: baseDate,
      );
      final resuelta = SolicitudData(
        id: '3', cuotaId: '', nroRecibo: '', tipo: '', descripcion: '',
        estado: SolicitudEstado.resuelta, fecha: baseDate,
      );
      final rechazada = SolicitudData(
        id: '4', cuotaId: '', nroRecibo: '', tipo: '', descripcion: '',
        estado: SolicitudEstado.rechazada, fecha: baseDate,
      );

      expect(pendiente.estado, SolicitudEstado.pendiente);
      expect(enRevision.estado, SolicitudEstado.enRevision);
      expect(resuelta.estado, SolicitudEstado.resuelta);
      expect(rechazada.estado, SolicitudEstado.rechazada);
    });

    test('campos opcionales pueden ser null', () {
      final minima = SolicitudData(
        id: 'S-min', cuotaId: '', nroRecibo: 'TK-000000', tipo: 'Test',
        descripcion: 'Desc', estado: SolicitudEstado.pendiente,
        fecha: baseDate,
      );

      expect(minima.respuesta, isNull);
      expect(minima.propietarioId, isNull);
      expect(minima.propietarioNombre, isNull);
    });

    test('cuotaId y nroRecibo pueden ser vacíos', () {
      final sinRef = SolicitudData(
        id: 'S-2', cuotaId: '', nroRecibo: '', tipo: 'Test',
        descripcion: 'Test', estado: SolicitudEstado.pendiente,
        fecha: baseDate,
      );

      expect(sinRef.cuotaId, isEmpty);
      expect(sinRef.nroRecibo, isEmpty);
    });
  });

  group('SolicitudEstado enum', () {
    test('tiene 4 valores', () {
      expect(SolicitudEstado.values.length, 4);
    });

    test('valores en orden correcto', () {
      expect(SolicitudEstado.values[0], SolicitudEstado.pendiente);
      expect(SolicitudEstado.values[1], SolicitudEstado.enRevision);
      expect(SolicitudEstado.values[2], SolicitudEstado.resuelta);
      expect(SolicitudEstado.values[3], SolicitudEstado.rechazada);
    });
  });
}
