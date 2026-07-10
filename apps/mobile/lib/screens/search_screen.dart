import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../core/database/app_database.dart';
import '../core/database/daos/propietario_dao.dart';
import '../core/sync/sync_service.dart';
import 'auth/auth_cubit.dart';
import 'cobro/payment_screen.dart';

/// Pantalla de búsqueda de propietarios por Etapa, Casa y nombre/teléfono.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  final _propietarioDao = PropietarioDao(AppDatabase.instance);

  // Data for dropdowns
  List<Etapa> _etapas = [];
  List<Casa> _casas = [];

  // Selected values
  String? _selectedEtapaId;
  String? _selectedCasaId;

  // Results
  List<PropietarioConInfo> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  StreamSubscription<SyncResult>? _syncSub;

  @override
  void initState() {
    super.initState();
    _loadEtapas();
    if (SyncService.isInitialized) {
      _syncSub = SyncService.instance.onSyncResult.listen(_onSyncResult);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _syncSub?.cancel();
    super.dispose();
  }

  void _onSyncResult(SyncResult result) {
    if (!mounted) return;
    if (result.conflicts > 0 && result.errors == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.conflicts} pago(s) ya estaban registrados en el servidor',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
        ),
      );
    } else if (result.errors > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.errors} pago(s) no pudieron sincronizarse'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _loadEtapas() async {
    final db = AppDatabase.instance;
    final etapas = await (db.select(db.etapas)
      ..orderBy(
        ([
          (t) => OrderingTerm.asc(t.nombre),
        ]),
      ))
        .get();
    if (mounted) {
      setState(() => _etapas = etapas);
    }
  }

  Future<void> _loadCasas(String etapaId) async {
    final db = AppDatabase.instance;
    final casas = await (db.select(db.casas)
      ..where((t) => t.etapaId.equals(etapaId))
      ..orderBy(
        ([
          (t) => OrderingTerm.asc(t.direccionInterna),
        ]),
      ))
        .get();
    if (mounted) {
      setState(() => _casas = casas);
    }
  }

  void _onEtapaChanged(String? etapaId) {
    setState(() {
      _selectedEtapaId = etapaId;
      _selectedCasaId = null;
      _casas = [];
    });
    if (etapaId != null) {
      _loadCasas(etapaId);
    }
  }

  Future<void> _buscar() async {
    setState(() => _isLoading = true);

    try {
      // Necesitamos un tenantId. Como aún no hay login, usamos un valor
      // por defecto. El tenantId se obtendrá del usuario autenticado.
      const tenantId = 'default';

      final results = await _propietarioDao.buscarCompleto(
        tenantId: tenantId,
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        etapaId: _selectedEtapaId,
        casaId: _selectedCasaId,
      );

      if (mounted) {
        setState(() {
          _results = results;
          _hasSearched = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _nombreController.clear();
      _telefonoController.clear();
      _selectedEtapaId = null;
      _selectedCasaId = null;
      _casas = [];
      _results = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Propietarios'),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          if (_hasSearched)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Limpiar filtros',
              onPressed: _limpiarFiltros,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirRegistroPropietario,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo propietario'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Etapa dropdown
                // ignore: deprecated_member_use — value necesario para control reactivo
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedEtapaId,
                  decoration: const InputDecoration(
                    labelText: 'Etapa',
                    prefixIcon: Icon(Icons.layers_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las etapas'),
                    ),
                    ..._etapas.map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.nombre),
                      ),
                    ),
                  ],
                  onChanged: _onEtapaChanged,
                ),
                const SizedBox(height: 8),

                // Casa dropdown
                // ignore: deprecated_member_use — value necesario para control reactivo
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedCasaId,
                  decoration: const InputDecoration(
                    labelText: 'Casa',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las casas'),
                    ),
                    ..._casas.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.direccionInterna),
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedCasaId = val),
                ),
                const SizedBox(height: 8),

                // Nombre + Teléfono + Botón
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _buscar,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: const Text('Buscar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Resultados ────────────────────────────────────
          Expanded(
            child: _buildResults(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 72,
              color: colorScheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona filtros y presiona Buscar',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: colorScheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            '${_results.length} propietario${_results.length == 1 ? '' : 's'} encontrado${_results.length == 1 ? '' : 's'}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: _results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = _results[index];
              return _PropietarioCard(
                item: item,
                onTap: () => _mostrarDetalle(item),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthCubit>().logout();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _abrirRegistroPropietario() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RegistroPropietarioSheet(
        onRegistrado: () {
          // Refrescar resultados si hay una búsqueda activa
          if (_hasSearched) {
            _buscar();
          }
        },
      ),
    );
  }

  void _mostrarDetalle(PropietarioConInfo item) {
    final cobrado = showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PropietarioDetalleSheet(
        item: item,
        onCobrar: () => Navigator.of(ctx).pop(true),
      ),
    );

    // Si el usuario presionó "Cobrar", navegamos al PaymentScreen
    cobrado.then((shouldNavigate) {
      if (shouldNavigate == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              propietario: item.propietario,
              casaDireccion: item.casaDireccion,
              etapaNombre: item.etapaNombre,
            ),
          ),
        );
      }
    });
  }
}

// ════════════════════════════════════════════════════════════
// TARJETA DE RESULTADO
// ════════════════════════════════════════════════════════════

class _PropietarioCard extends StatelessWidget {
  final PropietarioConInfo item;
  final VoidCallback onTap;

  const _PropietarioCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(
                  item.propietario.nombre.isNotEmpty
                      ? item.propietario.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.propietario.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.casaDireccion,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.layers_outlined,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.etapaNombre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    if (item.propietario.telefono.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.propietario.telefono,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BOTTOM SHEET — DETALLE DEL PROPIETARIO
// ════════════════════════════════════════════════════════════

class _PropietarioDetalleSheet extends StatelessWidget {
  final PropietarioConInfo item;
  final VoidCallback? onCobrar;

  const _PropietarioDetalleSheet({required this.item, this.onCobrar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final p = item.propietario;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(
                    p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (p.email != null && p.email!.isNotEmpty)
                        Text(
                          p.email!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info sections
            _InfoSection(
              icon: Icons.home_outlined,
              title: 'Casa',
              value: item.casaDireccion,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _InfoSection(
              icon: Icons.layers_outlined,
              title: 'Etapa',
              value: item.etapaNombre,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _InfoSection(
              icon: Icons.phone_outlined,
              title: 'Teléfono',
              value: p.telefono.isNotEmpty ? p.telefono : '—',
              colorScheme: colorScheme,
            ),
            if (p.email != null && p.email!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoSection(
                icon: Icons.email_outlined,
                title: 'Email',
                value: p.email!,
                colorScheme: colorScheme,
              ),
            ],
            const SizedBox(height: 12),
            _InfoSection(
              icon: Icons.calendar_today_outlined,
              title: 'Registrado',
              value: DateFormat('d MMM yyyy', 'es').format(p.createdAt),
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => onCobrar?.call(),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ColorScheme colorScheme;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// BOTTOM SHEET — REGISTRO INLINE DE PROPIETARIO
// ════════════════════════════════════════════════════════════

/// Modal bottom sheet para registrar un nuevo propietario de forma inline.
/// Crea tanto el propietario como su tenencia en una transacción.
class _RegistroPropietarioSheet extends StatefulWidget {
  final VoidCallback? onRegistrado;

  const _RegistroPropietarioSheet({this.onRegistrado});

  @override
  State<_RegistroPropietarioSheet> createState() =>
      _RegistroPropietarioSheetState();
}

class _RegistroPropietarioSheetState
    extends State<_RegistroPropietarioSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _propietarioDao = PropietarioDao(AppDatabase.instance);

  List<Etapa> _etapas = [];
  List<Casa> _casas = [];
  String? _selectedEtapaId;
  String? _selectedCasaId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadEtapas();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEtapas() async {
    final db = AppDatabase.instance;
    final etapas = await (db.select(db.etapas)
          ..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .get();
    if (mounted) setState(() => _etapas = etapas);
  }

  Future<void> _loadCasas(String etapaId) async {
    final db = AppDatabase.instance;
    final casas = await (db.select(db.casas)
          ..where((t) => t.etapaId.equals(etapaId))
          ..orderBy([(t) => OrderingTerm.asc(t.direccionInterna)]))
        .get();
    if (mounted) setState(() => _casas = casas);
  }

  void _onEtapaChanged(String? id) {
    setState(() {
      _selectedEtapaId = id;
      _selectedCasaId = null;
      _casas = [];
    });
    if (id != null) _loadCasas(id);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCasaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una casa para el propietario'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final name = _nombreCtrl.text.trim();
      final namePrefix = name.length >= 3
          ? name.substring(0, 3).toUpperCase()
          : name.toUpperCase();
      final propId = 'PRO_${now.microsecondsSinceEpoch}_$namePrefix';
      final email = _emailCtrl.text.trim();

      await _propietarioDao.insertConTenencia(
        propietario: PropietariosCompanion.insert(
          id: propId,
          nombre: name,
          telefono: _telefonoCtrl.text.trim(),
          tenantId: 'default',
          email: email.isEmpty ? const Value.absent() : Value(email),
          createdAt: now,
          updatedAt: now,
        ),
        casaId: _selectedCasaId!,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRegistrado?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Propietario "${_nombreCtrl.text.trim()}" registrado'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Text(
                'Nuevo propietario',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // Teléfono
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Etapa
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedEtapaId,
                decoration: const InputDecoration(
                  labelText: 'Etapa *',
                  prefixIcon: Icon(Icons.layers_outlined),
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _etapas
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.nombre),
                        ))
                    .toList(),
                onChanged: _onEtapaChanged,
              ),
              const SizedBox(height: 12),

              // Casa
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedCasaId,
                decoration: const InputDecoration(
                  labelText: 'Casa *',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _casas
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.direccionInterna),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCasaId = v),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _guardar,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar propietario'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

