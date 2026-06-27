// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/pedido.dart';
import '../utils/constants.dart';
import 'catalogo_screen.dart';
import 'pedidos_screen.dart';
import 'perfil_negocio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _pantallas = const [
    _PanelInicio(),
    CatalogoScreen(),
    PedidosScreen(),
    PerfilNegocioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: kColorPrimarioClaro,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: kColorPrimario),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: kColorPrimario),
            label: 'Catálogo',
          ),
          // Badge de pedidos pendientes
          NavigationDestination(
            icon: StreamBuilder<List<Pedido>>(
              stream: SupabaseService.instance.pedidosPendientesStream(),
              builder: (_, snap) {
                final count = snap.data?.length ?? 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: kColorError,
                  child: const Icon(Icons.receipt_long_outlined),
                );
              },
            ),
            selectedIcon: const Icon(Icons.receipt_long, color: kColorPrimario),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: kColorPrimario),
            label: 'Mi local',
          ),
        ],
      ),
    );
  }
}

// ─── Panel de inicio ──────────────────────────────────────────────────────

class _PanelInicio extends StatelessWidget {
  const _PanelInicio();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tu Vendedor',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                color: kColorTexto)),
      ),
      body: StreamBuilder<List<Pedido>>(
        stream: SupabaseService.instance.pedidosActivosStream(),
        builder: (context, snap) {
          final pedidos = snap.data ?? [];
          final pendientes = pedidos
              .where((p) => p.estado == EstadoPedido.pendiente).length;
          final preparando = pedidos
              .where((p) => p.estado == EstadoPedido.preparando).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Resumen rápido
              Row(children: [
                Expanded(child: _ResumenCard(
                  label: 'Pendientes',
                  valor: '$pendientes',
                  color: const Color(0xFFEF6C00),
                  icono: Icons.hourglass_empty,
                )),
                const SizedBox(width: 10),
                Expanded(child: _ResumenCard(
                  label: 'Preparando',
                  valor: '$preparando',
                  color: kColorPrimario,
                  icono: Icons.restaurant,
                )),
              ]),
              const SizedBox(height: 24),

              // Accesos rápidos
              const Text('Accesos rápidos',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: kColorTextoSub)),
              const SizedBox(height: 10),
              _AccesoRapido(
                icono: Icons.grid_view,
                titulo: 'Gestionar catálogo',
                subtitulo: 'Agregar, editar o quitar productos',
                onTap: () => _irA(context, 1),
              ),
              const SizedBox(height: 8),
              _AccesoRapido(
                icono: Icons.receipt_long,
                titulo: 'Ver pedidos activos',
                subtitulo: 'Gestiona los pedidos en curso',
                onTap: () => _irA(context, 2),
              ),
              const SizedBox(height: 8),
              _AccesoRapido(
                icono: Icons.store,
                titulo: 'Configurar mi local',
                subtitulo: 'Horario, ubicación y datos del negocio',
                onTap: () => _irA(context, 3),
              ),
            ],
          );
        },
      ),
    );
  }

  void _irA(BuildContext context, int tab) {
    final home = context.findAncestorStateOfType<_HomeScreenState>();
    home?.setState(() => home._tab = tab);
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.label, required this.valor,
      required this.color, required this.icono});
  final String label, valor;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: TextStyle(fontSize: 24,
              fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontSize: 11,
              color: color.withOpacity(0.8))),
        ]),
      ]),
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  const _AccesoRapido({required this.icono, required this.titulo,
      required this.subtitulo, required this.onTap});
  final IconData icono;
  final String titulo, subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kColorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kColorBorde),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: kColorPrimarioClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: kColorPrimario, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: kColorTexto)),
              Text(subtitulo, style: const TextStyle(fontSize: 12,
                  color: kColorTextoSub)),
            ],
          )),
          const Icon(Icons.chevron_right, color: kColorBorde),
        ]),
      ),
    );
  }
}
