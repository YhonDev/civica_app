import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/timeline_widget.dart';
import 'dashboard_repository.dart';
import 'models/dashboard_data.dart';

class ActividadAdminScreen extends StatefulWidget {
  const ActividadAdminScreen({super.key});

  @override
  State<ActividadAdminScreen> createState() => _ActividadAdminScreenState();
}

class _ActividadAdminScreenState extends State<ActividadAdminScreen> {
  final _repo = DashboardRepository();
  List<ActividadItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _repo.getDashboard(DateTime.now().month, DateTime.now().year);
    if (mounted) {
      setState(() {
        _items = data.actividadReciente;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Actividad del Sistema',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: TimelineWidget(
                items: _items.map((a) => TimelineItem(
                  id: a.id,
                  tipo: a.tipo,
                  descripcion: a.descripcion,
                  usuario: a.usuario,
                  timestamp: a.timestamp,
                  hace: a.hace,
                )).toList(),
              ),
            ),
    );
  }
}
