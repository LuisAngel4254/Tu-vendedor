// models/pedido.dart

enum EstadoPedido { pendiente, preparando, listo, entregado, cancelado }

class ItemPedido {
  final String productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;

  const ItemPedido({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
    'productoId': productoId,
    'nombreProducto': nombreProducto,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
  };

  factory ItemPedido.fromMap(Map<String, dynamic> m) => ItemPedido(
    productoId: m['productoId'] ?? '',
    nombreProducto: m['nombreProducto'] ?? '',
    cantidad: m['cantidad'] ?? 1,
    precioUnitario: (m['precioUnitario'] ?? 0).toDouble(),
  );
}

class Pedido {
  final String id;
  final String clienteNombre;
  final String clienteTelefono;
  final List<ItemPedido> items;
  final EstadoPedido estado;
  final String metodoPago;      // 'yape', 'plin', 'visa', 'efectivo'
  final String? notas;
  final bool esDelivery;
  final String? direccionEntrega;
  final DateTime? horaEntregaProgramada;  // para pedidos fuera de horario
  final DateTime creadoEn;

  const Pedido({
    required this.id,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.items,
    this.estado = EstadoPedido.pendiente,
    required this.metodoPago,
    this.notas,
    this.esDelivery = false,
    this.direccionEntrega,
    this.horaEntregaProgramada,
    required this.creadoEn,
  });

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);

  String get estadoLabel {
    switch (estado) {
      case EstadoPedido.pendiente:   return 'Pendiente';
      case EstadoPedido.preparando:  return 'Preparando';
      case EstadoPedido.listo:       return 'Listo';
      case EstadoPedido.entregado:   return 'Entregado';
      case EstadoPedido.cancelado:   return 'Cancelado';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'clienteNombre': clienteNombre,
    'clienteTelefono': clienteTelefono,
    'items': items.map((i) => i.toMap()).toList(),
    'estado': estado.name,
    'metodoPago': metodoPago,
    'notas': notas,
    'esDelivery': esDelivery,
    'direccionEntrega': direccionEntrega,
    'horaEntregaProgramada': horaEntregaProgramada?.toIso8601String(),
    'creadoEn': creadoEn.toIso8601String(),
  };

  factory Pedido.fromMap(Map<String, dynamic> m) => Pedido(
    id: m['id'] ?? '',
    clienteNombre: m['clienteNombre'] ?? '',
    clienteTelefono: m['clienteTelefono'] ?? '',
    items: (m['items'] as List? ?? [])
        .map((i) => ItemPedido.fromMap(i))
        .toList(),
    estado: EstadoPedido.values.firstWhere(
      (e) => e.name == m['estado'],
      orElse: () => EstadoPedido.pendiente,
    ),
    metodoPago: m['metodoPago'] ?? 'efectivo',
    notas: m['notas'],
    esDelivery: m['esDelivery'] ?? false,
    direccionEntrega: m['direccionEntrega'],
    horaEntregaProgramada: m['horaEntregaProgramada'] != null
        ? DateTime.tryParse(m['horaEntregaProgramada'])
        : null,
    creadoEn: DateTime.tryParse(m['creadoEn'] ?? '') ?? DateTime.now(),
  );

  Pedido copyWith({EstadoPedido? estado}) => Pedido(
    id: id,
    clienteNombre: clienteNombre,
    clienteTelefono: clienteTelefono,
    items: items,
    estado: estado ?? this.estado,
    metodoPago: metodoPago,
    notas: notas,
    esDelivery: esDelivery,
    direccionEntrega: direccionEntrega,
    horaEntregaProgramada: horaEntregaProgramada,
    creadoEn: creadoEn,
  );
}
