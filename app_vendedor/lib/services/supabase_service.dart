// services/supabase_service.dart
// Toda operación con Supabase pasa por aquí.
// Las pantallas nunca llaman a Supabase directamente.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/negocio.dart';
import '../models/producto.dart';
import '../models/pedido.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final _db = Supabase.instance.client;

  // ─── NEGOCIO ──────────────────────────────────────────────────────────────

  Future<void> guardarNegocio(Negocio negocio) async {
    await _db.from('negocio').upsert({
      'id': 'principal',
      'nombre': negocio.nombre,
      'foto_url': negocio.fotoUrl,
      'whatsapp_numero': negocio.whatsappNumero,
      'horario_apertura': negocio.horario.apertura,
      'horario_cierre': negocio.horario.cierre,
      'dias_activos': negocio.horario.diasActivos,
      'ubicacion_lat': negocio.ubicacion.lat,
      'ubicacion_lng': negocio.ubicacion.lng,
      'ubicacion_direccion': negocio.ubicacion.direccionTexto,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<Negocio?> obtenerNegocio() async {
    final res = await _db
        .from('negocio')
        .select()
        .eq('id', 'principal')
        .maybeSingle();
    if (res == null) return null;
    return _negocioFromMap(res);
  }

  Stream<Negocio?> negocioStream() {
    return _db
        .from('negocio')
        .stream(primaryKey: ['id'])
        .eq('id', 'principal')
        .map((rows) => rows.isEmpty ? null : _negocioFromMap(rows.first));
  }

  Negocio _negocioFromMap(Map<String, dynamic> m) => Negocio(
    id: m['id'] ?? 'principal',
    nombre: m['nombre'] ?? '',
    fotoUrl: m['foto_url'],
    whatsappNumero: m['whatsapp_numero'] ?? '',
    horario: HorarioAtencion(
      apertura: m['horario_apertura'] ?? '08:00',
      cierre: m['horario_cierre'] ?? '22:00',
      diasActivos: List<int>.from(m['dias_activos'] ?? [1, 2, 3, 4, 5]),
    ),
    ubicacion: Ubicacion(
      lat: (m['ubicacion_lat'] ?? 0).toDouble(),
      lng: (m['ubicacion_lng'] ?? 0).toDouble(),
      direccionTexto: m['ubicacion_direccion'] ?? '',
    ),
    creadoEn: DateTime.now(),
    actualizadoEn: DateTime.tryParse(m['actualizado_en'] ?? '') ?? DateTime.now(),
  );

  // ─── PRODUCTOS ────────────────────────────────────────────────────────────

  Future<void> guardarProducto(Producto producto) async {
    await _db.from('productos').upsert({
      'id': producto.id,
      'slot': producto.slot,
      'nombre': producto.nombre,
      'precio': producto.precio,
      'stock_total': producto.stockTotal,
      'stock_actual': producto.stockActual,
      'foto_url': producto.fotoUrl,
      'activo': producto.activo,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<void> eliminarProducto(String productoId) async {
    await _db.from('productos').delete().eq('id', productoId);
  }

  Future<void> descontarStock(String productoId, int cantidad) async {
    // Supabase no tiene FieldValue.increment, usamos RPC
    await _db.rpc('descontar_stock', params: {
      'p_id': productoId,
      'p_cantidad': cantidad,
    });
  }

  Stream<List<Producto>> productosStream() {
    return _db
        .from('productos')
        .stream(primaryKey: ['id'])
        .order('slot')
        .map((rows) => rows.map((r) => _productoFromMap(r)).toList());
  }

  Producto _productoFromMap(Map<String, dynamic> m) => Producto(
    id: m['id'] ?? '',
    slot: m['slot'] ?? 0,
    nombre: m['nombre'] ?? '',
    precio: (m['precio'] ?? 0).toDouble(),
    stockTotal: m['stock_total'] ?? 0,
    stockActual: m['stock_actual'] ?? 0,
    fotoUrl: m['foto_url'],
    activo: m['activo'] ?? true,
    actualizadoEn: DateTime.tryParse(m['actualizado_en'] ?? '') ?? DateTime.now(),
  );

  // ─── PEDIDOS ──────────────────────────────────────────────────────────────

  Future<void> guardarPedido(Pedido pedido) async {
    await _db.from('pedidos').insert({
      'id': pedido.id,
      'cliente_nombre': pedido.clienteNombre,
      'cliente_telefono': pedido.clienteTelefono,
      'items': pedido.items.map((i) => i.toMap()).toList(),
      'total': pedido.total,
      'estado': pedido.estado.name,
      'metodo_pago': pedido.metodoPago,
      'notas': pedido.notas,
      'es_delivery': pedido.esDelivery,
      'direccion_entrega': pedido.direccionEntrega,
      'hora_entrega_programada': pedido.horaEntregaProgramada?.toIso8601String(),
      'creado_en': pedido.creadoEn.toIso8601String(),
    });
  }

  Future<void> actualizarEstadoPedido(
      String pedidoId, EstadoPedido nuevoEstado) async {
    await _db
        .from('pedidos')
        .update({'estado': nuevoEstado.name})
        .eq('id', pedidoId);
  }

  Stream<List<Pedido>> pedidosPendientesStream() {
    return _db
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .eq('estado', 'pendiente')
        .order('creado_en')
        .map((rows) => rows.map((r) => _pedidoFromMap(r)).toList());
  }

  Stream<List<Pedido>> pedidosActivosStream() {
    return _db
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .order('creado_en')
        .map((rows) => rows
            .where((r) =>
                r['estado'] == 'pendiente' || r['estado'] == 'preparando')
            .map((r) => _pedidoFromMap(r))
            .toList());
  }

  Pedido _pedidoFromMap(Map<String, dynamic> m) => Pedido(
    id: m['id'] ?? '',
    clienteNombre: m['cliente_nombre'] ?? '',
    clienteTelefono: m['cliente_telefono'] ?? '',
    items: (m['items'] as List? ?? [])
        .map((i) => ItemPedido.fromMap(Map<String, dynamic>.from(i)))
        .toList(),
    estado: EstadoPedido.values.firstWhere(
      (e) => e.name == m['estado'],
      orElse: () => EstadoPedido.pendiente,
    ),
    metodoPago: m['metodo_pago'] ?? 'efectivo',
    notas: m['notas'],
    esDelivery: m['es_delivery'] ?? false,
    direccionEntrega: m['direccion_entrega'],
    horaEntregaProgramada: m['hora_entrega_programada'] != null
        ? DateTime.tryParse(m['hora_entrega_programada'])
        : null,
    creadoEn: DateTime.tryParse(m['creado_en'] ?? '') ?? DateTime.now(),
  );
}
