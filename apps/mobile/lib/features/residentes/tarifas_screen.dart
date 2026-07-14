import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'tarifas_repository.dart';
import 'comunidad_repository.dart';
import 'package:intl/intl.dart';

class TarifasScreen extends StatefulWidget {
  const TarifasScreen({super.key});

  @override
  State<TarifasScreen> createState() => _TarifasScreenState();
}

class _TarifasScreenState extends State<TarifasScreen> {
  final _repository = TarifasRepository();
  final _comunidadRepo = ComunidadRepository();
  bool _loading = true;
  Map<String, dynamic> _tarifas = {};
  String? _proyectoId;

  @override
  void initState() {
    super.initState();
    _loadTarifas();
  }

  Future<void> _loadTarifas() async {
    try {
      final proyectos = await _comunidadRepo.getProyectos();
      if (proyectos.isNotEmpty) {
        _proyectoId = proyectos.first['id'];
        
        final response = await _repository.getTarifasVigentes(_proyectoId!);
        
        if (mounted) {
          setState(() {
            _tarifas = response['tarifas'] ?? {};
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading tarifas: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editarTarifa(String id, String frecuencia, int currentMonto) async {
    final controller = TextEditingController(text: currentMonto.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Tarifa $frecuencia'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monto en pesos',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), ''));
              Navigator.pop(context, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    if (result != null && result > 0) {
      setState(() => _loading = true);
      try {
        await _repository.actualizarTarifa(id, result);
        await _loadTarifas();
      } catch (e) {
        debugPrint('Error updating tarifa: $e');
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar la tarifa')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Tarifas'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                Text(
                  'Tarifas Vigentes',
                  style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_tarifas.containsKey('MENSUAL') && _tarifas['MENSUAL'] != null)
                  _buildTarifaCard(_tarifas['MENSUAL']),
                if (_tarifas.containsKey('QUINCENAL') && _tarifas['QUINCENAL'] != null)
                  _buildTarifaCard(_tarifas['QUINCENAL']),
              ],
            ),
    );
  }

  Widget _buildTarifaCard(Map<String, dynamic> tarifa) {
    final montoStr = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0).format(tarifa['montoPesos']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: Icon(Icons.receipt_long, color: AppColors.primary),
        title: Text('Frecuencia: ${tarifa['frecuencia']}'),
        subtitle: Text('Monto: $montoStr'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editarTarifa(tarifa['id'], tarifa['frecuencia'], tarifa['montoPesos']),
        ),
      ),
    );
  }
}
