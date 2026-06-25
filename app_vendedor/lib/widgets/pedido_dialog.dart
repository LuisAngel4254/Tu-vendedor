// widgets/pedido_dialog.dart
// Ventana emergente que aparece con cada pedido nuevo.
// Solo tiene dos opciones: Aceptar o Cancelar.
// Si cancela → se abre WhatsApp automáticamente para explicar al cliente.

import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../utils/constants.dart';

class PedidoDialog extends StatelessWidget {
  const PedidoDialog({super.key, required this.pedido});
  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: kColorPrimarioClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    color: kColorPrimario, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nuevo pedido',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: kColorTexto)),
                  Text(pedido.clienteNombre,
                      style: const TextStyle(fontSize: 12, color: kColorTextoSub)),
                ]),
              ),
            ]),

            const SizedBox(height: 14),
            const Divider(height: 1, color: kColorBorde),
            const SizedBox(height: 12),

            // Items
            ...pedido.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Text('${item.cantidad}x',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: kColorPrimario)),
                const SizedBox(width: 6),
                Expanded(child: Text(item.nombreProducto,
                    style: const TextStyle(fontSize: 13, color: kColorTexto))),
                Text('S/${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: kColorTextoSub)),
              ]),
            )),

            const SizedBox(height: 8),
            const Divider(height: 1, color: kColorBorde),
            const SizedBox(height: 8),

            // Total y pago
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: kColorTexto)),
              Text('S/${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: kColorPrimario)),
            ]),
            const SizedBox(height: 4),
            Text('Pago: ${pedido.metodoPago.toUpperCase()}',
                style: const TextStyle(fontSize: 11, color: kColorTextoSub)),

            if (pedido.notas != null && pedido.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('📝 ${pedido.notas}',
                    style: const TextStyle(fontSize: 12,
                        color: Color(0xFF856404))),
              ),
            ],

            const SizedBox(height: 16),

            // Botones
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kColorError),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(color: kColorError,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorPrimario,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Aceptar',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),

            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Cancelar abrirá WhatsApp para contactar al cliente',
                style: TextStyle(fontSize: 10, color: kColorTextoSub),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra el dialog y devuelve true (aceptar) o false (cancelar).
Future<bool?> mostrarPedidoDialog(BuildContext context, Pedido pedido) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // obliga a elegir una opción
    builder: (_) => PedidoDialog(pedido: pedido),
  );
}
