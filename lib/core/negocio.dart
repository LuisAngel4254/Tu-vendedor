// models/negocio.dart

class HorarioAtencion {
  final String apertura; // "08:00"
  final String cierre;   // "22:00"
  final List<int> diasActivos; // 1=lunes … 7=domingo

  const HorarioAtencion({
    required this.apertura,
    required this.cierre,
    required this.diasActivos,
  });

  Map<String, dynamic> toMap() => {
    'apertura': apertura,
    'cierre': cierre,
    'diasActivos': diasActivos,
  };

  factory HorarioAtencion.fromMap(Map<String, dynamic> m) => HorarioAtencion(
    apertura: m['apertura'] ?? '08:00',
    cierre: m['cierre'] ?? '22:00',
    diasActivos: List<int>.from(m['diasActivos'] ?? [1, 2, 3, 4, 5]),
  );
}

class Ubicacion {
  final double lat;
  final double lng;
  final String direccionTexto; // dirección legible para mostrar al cliente

  const Ubicacion({
    required this.lat,
    required this.lng,
    required this.direccionTexto,
  });

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    'direccion': direccionTexto,
  };

  factory Ubicacion.fromMap(Map<String, dynamic> m) => Ubicacion(
    lat: (m['lat'] ?? 0).toDouble(),
    lng: (m['lng'] ?? 0).toDouble(),
    direccionTexto: m['direccion'] ?? '',
  );
}

class Negocio {
  final String id;
  final String nombre;           // obligatorio
  final String? fotoUrl;         // opcional
  final HorarioAtencion horario; // obligatorio
  final Ubicacion ubicacion;     // obligatorio
  final String whatsappNumero;   // obligatorio — se comparte con clientes
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const Negocio({
    required this.id,
    required this.nombre,
    this.fotoUrl,
    required this.horario,
    required this.ubicacion,
    required this.whatsappNumero,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'fotoUrl': fotoUrl,
    'horario': horario.toMap(),
    'ubicacion': ubicacion.toMap(),
    'whatsappNumero': whatsappNumero,
    'creadoEn': creadoEn.toIso8601String(),
    'actualizadoEn': actualizadoEn.toIso8601String(),
  };

  factory Negocio.fromMap(Map<String, dynamic> m) => Negocio(
    id: m['id'] ?? '',
    nombre: m['nombre'] ?? '',
    fotoUrl: m['fotoUrl'],
    horario: HorarioAtencion.fromMap(m['horario'] ?? {}),
    ubicacion: Ubicacion.fromMap(m['ubicacion'] ?? {}),
    whatsappNumero: m['whatsappNumero'] ?? '',
    creadoEn: DateTime.tryParse(m['creadoEn'] ?? '') ?? DateTime.now(),
    actualizadoEn: DateTime.tryParse(m['actualizadoEn'] ?? '') ?? DateTime.now(),
  );

  Negocio copyWith({
    String? nombre,
    String? fotoUrl,
    HorarioAtencion? horario,
    Ubicacion? ubicacion,
    String? whatsappNumero,
  }) => Negocio(
    id: id,
    nombre: nombre ?? this.nombre,
    fotoUrl: fotoUrl ?? this.fotoUrl,
    horario: horario ?? this.horario,
    ubicacion: ubicacion ?? this.ubicacion,
    whatsappNumero: whatsappNumero ?? this.whatsappNumero,
    creadoEn: creadoEn,
    actualizadoEn: DateTime.now(),
  );
}
