// widgets/modulo_producto.dart
// Card de producto para el grid de 50 módulos.
// Estado vacío: muestra "+" para agregar.
// Estado activo: muestra foto, nombre, precio, stock.
// Estado agotado: muestra todo con overlay gris bloqueado.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/producto.dart';
import '../utils/constants.dart';

class ModuloProducto extends StatelessWidget {
  const ModuloProducto({
    super.key,
    required this.slot,
    this.producto,
    required this.onTap,
  });

  final int slot;
  final Producto? producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (producto == null) return _SlotVacio(onTap: onTap);
    if (producto!.agotado) return _SlotAgotado(producto: producto!, onTap: onTap);
    return _SlotActivo(producto: producto!, onTap: onTap);
  }
}

// ─── Slot vacío ───────────────────────────────────────────────────────────

class _SlotVacio extends StatelessWidget {
  const _SlotVacio({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kColorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kColorBorde,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: kColorBorde, size: 28),
            const SizedBox(height: 4),
            Text('Agregar', style: TextStyle(
                fontSize: 10, color: kColorBorde)),
          ],
        ),
      ),
    );
  }
}

// ─── Slot activo ──────────────────────────────────────────────────────────

class _SlotActivo extends StatelessWidget {
  const _SlotActivo({required this.producto, required this.onTap});
  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kColorBorde),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: producto.fotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: producto.fotoUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(color: kColorFondo),
                        errorWidget: (_, __, ___) => _FotoPlaceholder(),
                      )
                    : _FotoPlaceholder(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre,
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600, color: kColorTexto),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('S/${producto.precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11,
                              color: kColorPrimario, fontWeight: FontWeight.w600)),
                      Text('${producto.stockActual} und',
                          style: const TextStyle(fontSize: 10,
                              color: kColorTextoSub)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slot agotado ─────────────────────────────────────────────────────────

class _SlotAgotado extends StatelessWidget {
  const _SlotAgotado({required this.producto, required this.onTap});
  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // el local puede editar aunque esté agotado
      child: Stack(
        children: [
          // Card base igual al activo
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kColorBorde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: producto.fotoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: producto.fotoUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            color: Colors.grey,
                            colorBlendMode: BlendMode.saturation,
                          )
                        : _FotoPlaceholder(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(producto.nombre,
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kColorTextoSub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('S/${producto.precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11,
                              color: kColorTextoSub)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Overlay gris con "Agotado"
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('AGOTADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kColorFondo,
      child: const Center(
        child: Icon(Icons.image_outlined, color: kColorBorde, size: 28),
      ),
    );
  }
}
