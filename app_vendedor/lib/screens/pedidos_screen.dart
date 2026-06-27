// screens/pedidos_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pedido.dart';
import '../services/supabase_service.dart';
import '../widgets/pedido_dialog.dart';
import '../utils/constants.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  // IDs de pedidos que ya mostramos el dialog para no repetirlo
  final Set<String> _mostrados = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pedidos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                color: kColorTexto)),
      ),
      body: StreamBuilder<List<Pedido>>(
        stream: SupabaseService.instance.pedidosActivosStream(),
        builder: (context, snap) {
          // Mostrar dialog por cada pedido nuevo pendiente
          if (snap.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (final pedido in snap.data!) {
                if (pedido.estado == EstadoPedido.pendiente &&
                    !_mostrados.contains(pedido.id)) {
                  _mostrados.add(pedido.id);
                  _mostrarDialog(pedido);
                }
              }
            });
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: kColorPrimario));
          }

          final pedidos = snap.data ?? [];

          if (pedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: kColorBorde),
                  const SizedBox(height: 12),
                  const Text('Sin pedidos activos',
                      style: TextStyle(color: kColorTextoSub, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TarjetaPedido(
              pedido: pedidos[i],
              onCambiarEstado: (nuevoEstado) async {
                await SupabaseService.instance
                    .actualizarEstadoPedido(pedidos[i].id, nuevoEstado);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialog(Pedido pedido) async {
    final aceptado = await mostrarPedidoDialog(context, pedido);
    if (aceptado == true) {
      await SupabaseService.instance.actualizarEstadoPedido(
          pedido.id, EstadoPedido.preparando);
      // Descontar stock de cada ítem
      for (final item in pedido.items) {
        await SupabaseService.instance
            .descontarStock(item.productoId, item.cantidad);
      }
    } else if (aceptado == false) {
      await SupabaseService.instance.actualizarEstadoPedido(
          pedido.id, EstadoPedido.cancelado);
      // Abrir WhatsApp automáticamente para explicar cancelación
      final url = Uri.parse(
          'https://wa.me/${pedido.clienteTelefono}'
          '?text=Hola%20${Uri.encodeComponent(pedido.clienteNombre)},%20'
          'necesitamos%20contarte%20algo%20sobre%20tu%20pedido.');
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }
}

// ─── Tarjeta de pedido en la lista ────────────────────────────────────────

class _TarjetaPedido extends StatelessWidget {
  const _TarjetaPedido({required this.pedido, required this.onCambiarEstado});
  final Pedido pedido;
  final Future<void> Function(EstadoPedido) onCambiarEstado;

  Color get _colorEstado {
    switch (pedido.estado) {
      case EstadoPedido.pendiente:  return const Color(0xFFEF6C00);
      case EstadoPedido.preparando: return kColorPrimario;
      case EstadoPedido.listo:      return const Color(0xFF1565C0);
      default:                      return kColorTextoSub;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorBorde),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pedido.clienteNombre,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: kColorTexto)),
              Text(pedido.clienteTelefono,
                  style: const TextStyle(fontSize: 12, color: kColorTextoSub)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _colorEstado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(pedido.estadoLabel,
                style: TextStyle(fontSize: 11, color: _colorEstado,
                    fontWeight: FontWeight.w600)),
          ),
        ]),

        const SizedBox(height: 10),
        const Divider(height: 1, color: kColorBorde),
        const SizedBox(height: 8),

        // Items
        ...pedido.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Text('${item.cantidad}x ',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: kColorPrimario)),
            Expanded(child: Text(item.nombreProducto,
                style: const TextStyle(fontSize: 13, color: kColorTexto))),
            Text('S/${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: kColorTextoSub)),
          ]),
        )),

        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total: S/${pedido.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: kColorTexto)),
          Text(pedido.metodoPago.toUpperCase(),
              style: const TextStyle(fontSize: 11, color: kColorTextoSub)),
        ]),

        // Botón avanzar estado
        if (pedido.estado == EstadoPedido.preparando) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onCambiarEstado(EstadoPedido.listo),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Marcar como listo',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ]),
    );
  }
}
