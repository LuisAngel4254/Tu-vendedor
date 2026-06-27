// screens/producto_form_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/platform_info.dart';
import '../models/producto.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({
    super.key,
    required this.slot,
    this.productoExistente,
  });

  final int slot;
  final Producto? productoExistente;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  XFile? _fotoLocal;
  String? _fotoUrlExistente;
  bool _guardando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.productoExistente != null;
    if (_esEdicion) {
      _nombreCtrl.text = widget.productoExistente!.nombre;
      _precioCtrl.text = widget.productoExistente!.precio.toString();
      _stockCtrl.text = widget.productoExistente!.stockActual.toString();
      _fotoUrlExistente = widget.productoExistente!.fotoUrl;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();
    XFile? picked;
    if (PlatformInfo.instance.isMobile) {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: kColorPrimario),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: kColorPrimario),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      );
      if (source == null) return;
      picked = await picker.pickImage(source: source, imageQuality: 80);
    } else {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    }
    if (picked != null) setState(() => _fotoLocal = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      // TODO: subir _fotoLocal a Supabase Storage y obtener URL
      final producto = Producto(
        id: widget.productoExistente?.id ?? const Uuid().v4(),
        slot: widget.slot,
        nombre: _nombreCtrl.text.trim(),
        precio: double.parse(_precioCtrl.text.trim()),
        stockTotal: int.parse(_stockCtrl.text.trim()),
        stockActual: int.parse(_stockCtrl.text.trim()),
        fotoUrl: _fotoUrlExistente,
        activo: true,
        actualizadoEn: DateTime.now(),
      );

      await SupabaseService.instance.guardarProducto(producto);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kColorError),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('El slot quedará vacío y disponible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: kColorError))),
        ],
      ),
    );
    if (confirmar != true) return;
    await SupabaseService.instance
        .eliminarProducto(widget.productoExistente!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tieneImagen = _fotoLocal != null || _fotoUrlExistente != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_esEdicion ? 'Editar producto' : 'Agregar producto',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                color: kColorTexto)),
        actions: [
          if (_esEdicion)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: kColorError),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Foto
            GestureDetector(
              onTap: _elegirFoto,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: kColorPrimarioClaro,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kColorPrimario.withOpacity(0.25)),
                  image: tieneImagen ? DecorationImage(
                    image: _fotoLocal != null
                        ? (kIsWeb
                            ? NetworkImage(_fotoLocal!.path)
                            : FileImage(File(_fotoLocal!.path))) as ImageProvider
                        : NetworkImage(_fotoUrlExistente!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: tieneImagen
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: kColorPrimario.withOpacity(0.6)),
                          const SizedBox(height: 8),
                          const Text('Foto del producto (opcional)',
                              style: TextStyle(color: kColorPrimario,
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            _label('Nombre del producto', obligatorio: true),
            _campo(_nombreCtrl, 'Ej: Ceviche mixto',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es obligatorio' : null),
            const SizedBox(height: 16),

            // Precio y Stock en fila
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Precio (S/)', obligatorio: true),
                  _campo(_precioCtrl, '0.00',
                      tipo: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatorio';
                        if (double.tryParse(v) == null) return 'Número inválido';
                        return null;
                      }),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Stock disponible', obligatorio: true),
                  _campo(_stockCtrl, '0',
                      tipo: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatorio';
                        if (int.tryParse(v) == null) return 'Número inválido';
                        return null;
                      }),
                ],
              )),
            ]),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kColorPrimario,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_esEdicion ? 'Guardar cambios' : 'Agregar producto',
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String texto, {bool obligatorio = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text(texto, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: kColorTexto)),
      if (obligatorio) const Text(' *',
          style: TextStyle(color: kColorError, fontSize: 13)),
    ]),
  );

  Widget _campo(TextEditingController ctrl, String hint,
      {TextInputType? tipo, String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: tipo,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: kColorTexto),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kColorTextoSub, fontSize: 14),
          filled: true,
          fillColor: kColorFondo,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kColorBorde)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kColorBorde)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kColorPrimario, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kColorError)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      );
}
