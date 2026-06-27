// screens/catalogo_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';
import '../services/supabase_service.dart';
import '../widgets/modulo_producto.dart';
import '../utils/constants.dart';
import 'producto_form_screen.dart';

class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Catálogo',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                color: kColorTexto)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: StreamBuilder<List<Producto>>(
              stream: SupabaseService.instance.productosStream(),
              builder: (_, snap) {
                final count = snap.data?.where((p) => p.activo).length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kColorPrimarioClaro,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count / $kMaxProductos',
                      style: const TextStyle(fontSize: 11,
                          color: kColorPrimario, fontWeight: FontWeight.w500)),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Producto>>(
        stream: SupabaseService.instance.productosStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: kColorPrimario));
          }

          final productos = snap.data ?? [];
          // Construir mapa slot → producto
          final Map<int, Producto> porSlot = {
            for (var p in productos) p.slot: p
          };

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: kMaxProductos,
            itemBuilder: (context, index) {
              final slot = index + 1;
              final producto = porSlot[slot];
              return ModuloProducto(
                slot: slot,
                producto: producto,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductoFormScreen(
                      slot: slot,
                      productoExistente: producto,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
