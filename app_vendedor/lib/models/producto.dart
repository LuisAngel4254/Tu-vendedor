// models/producto.dart

class Producto {
  final String id;
  final int slot;          // posición en el grid (1-50)
  final String nombre;
  final double precio;
  final int stockTotal;    // cantidad inicial cargada por el local
  final int stockActual;   // se descuenta con cada pedido
  final String? fotoUrl;
  final bool activo;       // false = slot vacío
  final DateTime actualizadoEn;

  const Producto({
    required this.id,
    required this.slot,
    required this.nombre,
    required this.precio,
    required this.stockTotal,
    required this.stockActual,
    this.fotoUrl,
    this.activo = true,
    required this.actualizadoEn,
  });

  bool get agotado => stockActual <= 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'slot': slot,
    'nombre': nombre,
    'precio': precio,
    'stockTotal': stockTotal,
    'stockActual': stockActual,
    'fotoUrl': fotoUrl,
    'activo': activo,
    'actualizadoEn': actualizadoEn.toIso8601String(),
  };

  factory Producto.fromMap(Map<String, dynamic> m) => Producto(
    id: m['id'] ?? '',
    slot: m['slot'] ?? 0,
    nombre: m['nombre'] ?? '',
    precio: (m['precio'] ?? 0).toDouble(),
    stockTotal: m['stockTotal'] ?? 0,
    stockActual: m['stockActual'] ?? 0,
    fotoUrl: m['fotoUrl'],
    activo: m['activo'] ?? true,
    actualizadoEn: DateTime.tryParse(m['actualizadoEn'] ?? '') ?? DateTime.now(),
  );

  Producto copyWith({
    String? nombre,
    double? precio,
    int? stockTotal,
    int? stockActual,
    String? fotoUrl,
    bool? activo,
  }) => Producto(
    id: id,
    slot: slot,
    nombre: nombre ?? this.nombre,
    precio: precio ?? this.precio,
    stockTotal: stockTotal ?? this.stockTotal,
    stockActual: stockActual ?? this.stockActual,
    fotoUrl: fotoUrl ?? this.fotoUrl,
    activo: activo ?? this.activo,
    actualizadoEn: DateTime.now(),
  );
}
