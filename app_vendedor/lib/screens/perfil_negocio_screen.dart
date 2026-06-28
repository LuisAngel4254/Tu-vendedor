// screens/perfil_negocio_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../core/permissions_handler.dart';
import '../core/platform_info.dart';
import '../models/negocio.dart';
import '../services/supabase_service.dart';

const _kPrimary = Color(0xFF1B5E3B);
const _kPrimaryLight = Color(0xFFE8F5EE);
const _kError = Color(0xFFB71C1C);
const _kBorder = Color(0xFFDDE3DD);
const _kTextMain = Color(0xFF1A1F1A);
const _kTextSub = Color(0xFF6B756B);

class PerfilNegocioScreen extends StatefulWidget {
  const PerfilNegocioScreen({super.key});

  @override
  State<PerfilNegocioScreen> createState() => _PerfilNegocioScreenState();
}

class _PerfilNegocioScreenState extends State<PerfilNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _platform = PlatformInfo.instance;

  final _nombreCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _direccionManualCtrl = TextEditingController();

  XFile? _fotoLocal;
  String? _fotoUrlExistente;
  PermissionsResult? _permisos;
  Position? _posicionGps;
  TimeOfDay _apertura = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _cierre = const TimeOfDay(hour: 22, minute: 0);
  final List<bool> _diasActivos = [true, true, true, true, true, false, false];
  bool _guardando = false;
  bool _cargando = true;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _solicitarPermisos();
    _cargarDatosExistentes();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _whatsappCtrl.dispose();
    _direccionManualCtrl.dispose();
    super.dispose();
  }

  // ── Cargar datos existentes de Supabase ───────────────────────────────────

  Future<void> _cargarDatosExistentes() async {
    try {
      final negocio = await SupabaseService.instance.obtenerNegocio();
      if (negocio != null && mounted) {
        setState(() {
          _nombreCtrl.text = negocio.nombre;
          _whatsappCtrl.text = negocio.whatsappNumero;
          _fotoUrlExistente = negocio.fotoUrl;

          // Horario
          final aperturaParts = negocio.horario.apertura.split(':');
          final cierreParts = negocio.horario.cierre.split(':');
          _apertura = TimeOfDay(
            hour: int.parse(aperturaParts[0]),
            minute: int.parse(aperturaParts[1]),
          );
          _cierre = TimeOfDay(
            hour: int.parse(cierreParts[0]),
            minute: int.parse(cierreParts[1]),
          );

          // Días activos
          for (int i = 0; i < _diasActivos.length; i++) {
            _diasActivos[i] = negocio.horario.diasActivos.contains(i + 1);
          }

          // Dirección manual
          if (negocio.ubicacion.direccionTexto.isNotEmpty) {
            _direccionManualCtrl.text = negocio.ubicacion.direccionTexto;
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando negocio: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Permisos ───────────────────────────────────────────────────────────────

  Future<void> _solicitarPermisos() async {
    final result = await PermissionsHandler.instance.requestAll();
    if (mounted) setState(() => _permisos = result);
    if (result.location) await _obtenerUbicacionGps();
  }

  // ── Foto ───────────────────────────────────────────────────────────────────

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();
    XFile? picked;

    if (_platform.isMobile) {
      final source = await _mostrarFuenteFoto();
      if (source == null) return;
      picked = await picker.pickImage(source: source, imageQuality: 80);
    } else {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    }

    if (picked != null) setState(() => _fotoLocal = picked);
  }

  Future<ImageSource?> _mostrarFuenteFoto() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: _kBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kPrimary),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kPrimary),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Ubicación ──────────────────────────────────────────────────────────────

  Future<void> _obtenerUbicacionGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _posicionGps = pos);
    } catch (_) {}
  }

  // ── Horario ────────────────────────────────────────────────────────────────

  Future<void> _elegirHora({required bool esApertura}) async {
    final inicial = esApertura ? _apertura : _cierre;
    final elegida = await showTimePicker(
      context: context,
      initialTime: inicial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (elegida == null) return;
    setState(() {
      if (esApertura) {
        _apertura = elegida;
      } else {
        _cierre = elegida;
      }
    });
  }

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Guardar en Supabase ────────────────────────────────────────────────────

  bool get _ubicacionCompleta =>
      _posicionGps != null || _direccionManualCtrl.text.trim().isNotEmpty;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ubicacionCompleta) {
      setState(() => _errorMensaje = 'La ubicación del local es obligatoria.');
      return;
    }

    setState(() { _guardando = true; _errorMensaje = null; });

    try {
      final diasIndices = <int>[];
      for (int i = 0; i < _diasActivos.length; i++) {
        if (_diasActivos[i]) diasIndices.add(i + 1);
      }

      final negocio = Negocio(
        id: 'principal',
        nombre: _nombreCtrl.text.trim(),
        fotoUrl: _fotoUrlExistente,
        horario: HorarioAtencion(
          apertura: _formatHora(_apertura),
          cierre: _formatHora(_cierre),
          diasActivos: diasIndices,
        ),
        ubicacion: Ubicacion(
          lat: _posicionGps?.latitude ?? 0,
          lng: _posicionGps?.longitude ?? 0,
          direccionTexto: _posicionGps != null
              ? '${_posicionGps!.latitude.toStringAsFixed(5)}, ${_posicionGps!.longitude.toStringAsFixed(5)}'
              : _direccionManualCtrl.text.trim(),
        ),
        whatsappNumero: _whatsappCtrl.text.trim(),
        creadoEn: DateTime.now(),
        actualizadoEn: DateTime.now(),
      );

      // ✅ Guardar en Supabase
      await SupabaseService.instance.guardarNegocio(negocio);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local configurado correctamente ✓'),
            backgroundColor: _kPrimary,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMensaje = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Configura tu local',
            style: TextStyle(color: _kTextMain, fontSize: 17,
                fontWeight: FontWeight.w600)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_platform.label,
                style: const TextStyle(fontSize: 11, color: _kPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            _FotoSection(
              fotoLocal: _fotoLocal,
              fotoUrl: _fotoUrlExistente,
              onTap: _elegirFoto,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Nombre del local', obligatorio: true),
            _Campo(
              controller: _nombreCtrl,
              hint: 'Ej: Restaurante Asai',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Número de WhatsApp', obligatorio: true),
            _Campo(
              controller: _whatsappCtrl,
              hint: '+51 999 999 999',
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'Ingresa un número válido' : null,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Horario de atención', obligatorio: true),
            _HorarioRow(
              apertura: _apertura,
              cierre: _cierre,
              onElegirApertura: () => _elegirHora(esApertura: true),
              onElegirCierre: () => _elegirHora(esApertura: false),
            ),
            const SizedBox(height: 12),
            _DiasSemana(
              diasActivos: _diasActivos,
              onToggle: (i) => setState(() => _diasActivos[i] = !_diasActivos[i]),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Ubicación del local', obligatorio: true),
            if (_platform.hasGps) ...[
              _UbicacionGps(
                posicion: _posicionGps,
                onReintentar: _obtenerUbicacionGps,
              ),
              if (_posicionGps == null) ...[
                const SizedBox(height: 10),
                const Text('O ingresa la dirección manualmente:',
                    style: TextStyle(fontSize: 12, color: _kTextSub)),
                const SizedBox(height: 6),
                _Campo(
                  controller: _direccionManualCtrl,
                  hint: 'Av. Principal 123, Tacna',
                ),
              ],
            ] else ...[
              _Campo(
                controller: _direccionManualCtrl,
                hint: 'Av. Principal 123, Tacna',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La dirección es obligatoria' : null,
              ),
            ],
            if (_platform.needsMiuiExtraSetup) ...[
              const SizedBox(height: 12),
              _MiuiAviso(),
            ],
            if (_errorMensaje != null) ...[
              const SizedBox(height: 12),
              Text(_errorMensaje!,
                  style: const TextStyle(color: _kError, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            _BotonGuardar(guardando: _guardando, onTap: _guardar),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internos ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.texto, {this.obligatorio = false});
  final String texto;
  final bool obligatorio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(texto, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: _kTextMain)),
        if (obligatorio) const Text(' *',
            style: TextStyle(color: _kError, fontSize: 13)),
      ]),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.controller, required this.hint,
      this.keyboardType, this.validator});
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: _kTextMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSub, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7F9F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kError)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _FotoSection extends StatelessWidget {
  const _FotoSection({this.fotoLocal, this.fotoUrl, required this.onTap});
  final XFile? fotoLocal;
  final String? fotoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tieneImagen = fotoLocal != null || fotoUrl != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _kPrimaryLight,
          border: Border.all(color: _kPrimary.withOpacity(0.25), width: 1),
          image: tieneImagen ? DecorationImage(
            image: fotoLocal != null
                ? (kIsWeb ? NetworkImage(fotoLocal!.path)
                    : FileImage(File(fotoLocal!.path))) as ImageProvider
                : NetworkImage(fotoUrl!),
            fit: BoxFit.cover,
          ) : null,
        ),
        child: tieneImagen
            ? Align(alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 36, color: _kPrimary.withOpacity(0.6)),
                const SizedBox(height: 8),
                const Text('Foto del local (opcional)',
                    style: TextStyle(color: _kPrimary, fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Toca para agregar',
                    style: TextStyle(color: _kPrimary.withOpacity(0.5),
                        fontSize: 12)),
              ]),
      ),
    );
  }
}

class _HorarioRow extends StatelessWidget {
  const _HorarioRow({required this.apertura, required this.cierre,
      required this.onElegirApertura, required this.onElegirCierre});
  final TimeOfDay apertura, cierre;
  final VoidCallback onElegirApertura, onElegirCierre;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _HorarioBtn(label: 'Apertura', hora: _fmt(apertura),
          onTap: onElegirApertura)),
      const SizedBox(width: 10),
      const Text('—', style: TextStyle(color: _kTextSub)),
      const SizedBox(width: 10),
      Expanded(child: _HorarioBtn(label: 'Cierre', hora: _fmt(cierre),
          onTap: onElegirCierre)),
    ]);
  }
}

class _HorarioBtn extends StatelessWidget {
  const _HorarioBtn({required this.label, required this.hora, required this.onTap});
  final String label, hora;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF7F9F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder)),
        child: Row(children: [
          const Icon(Icons.access_time, size: 16, color: _kPrimary),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: _kTextSub)),
            Text(hora, style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600, color: _kTextMain)),
          ]),
        ]),
      ),
    );
  }
}

class _DiasSemana extends StatelessWidget {
  const _DiasSemana({required this.diasActivos, required this.onToggle});
  final List<bool> diasActivos;
  final void Function(int) onToggle;
  static const _dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final activo = diasActivos[i];
        return GestureDetector(
          onTap: () => onToggle(i),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activo ? _kPrimary : const Color(0xFFF7F9F7),
              border: Border.all(color: activo ? _kPrimary : _kBorder),
            ),
            child: Center(child: Text(_dias[i],
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: activo ? Colors.white : _kTextSub))),
          ),
        );
      }),
    );
  }
}

class _UbicacionGps extends StatelessWidget {
  const _UbicacionGps({this.posicion, required this.onReintentar});
  final Position? posicion;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    if (posicion != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: _kPrimaryLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kPrimary.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.location_on, color: _kPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '${posicion!.latitude.toStringAsFixed(5)}, ${posicion!.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 13, color: _kPrimary,
                fontWeight: FontWeight.w500))),
          GestureDetector(onTap: onReintentar,
              child: const Icon(Icons.refresh, color: _kPrimary, size: 18)),
        ]),
      );
    }
    return GestureDetector(
      onTap: onReintentar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF7F9F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder)),
        child: const Row(children: [
          Icon(Icons.location_searching, color: _kTextSub, size: 18),
          SizedBox(width: 8),
          Text('Obtener ubicación GPS',
              style: TextStyle(fontSize: 13, color: _kTextSub)),
        ]),
      ),
    );
  }
}

class _MiuiAviso extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.5)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, color: Color(0xFF856404), size: 16),
        SizedBox(width: 8),
        Expanded(child: Text(
          'En MIUI (Xiaomi): ve a Ajustes → Aplicaciones → Permisos y activa ubicación y notificaciones para esta app.',
          style: TextStyle(fontSize: 12, color: Color(0xFF856404), height: 1.4))),
      ]),
    );
  }
}

class _BotonGuardar extends StatelessWidget {
  const _BotonGuardar({required this.guardando, required this.onTap});
  final bool guardando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: guardando ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          disabledBackgroundColor: _kPrimary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: guardando
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Guardar configuración',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Colors.white)),
      ),
    );
  }
}