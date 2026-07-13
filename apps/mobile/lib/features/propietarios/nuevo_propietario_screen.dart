import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'comunidad_repository.dart';
import 'propietarios_repository.dart';

class NuevoPropietarioScreen extends StatefulWidget {
  const NuevoPropietarioScreen({super.key});

  @override
  State<NuevoPropietarioScreen> createState() => _NuevoPropietarioScreenState();
}

class _NuevoPropietarioScreenState extends State<NuevoPropietarioScreen> {
  final ComunidadRepository _comunidadRepo = ComunidadRepository();
  final PropietariosRepository _propietariosRepo = PropietariosRepository();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _etapasTree = [];

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  String _modalidadPago = 'MENSUAL';

  String? _selectedEtapaId;
  String? _selectedManzanaId;
  String? _selectedCasaId;

  String? _selectedEtapaName;
  String? _selectedManzanaName;
  String? _selectedCasaName;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTree() async {
    try {
      final tree = await _comunidadRepo.getArbolCompleto();
      setState(() {
        _etapasTree = tree;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _etapas => _etapasTree;
  
  List<Map<String, dynamic>> get _manzanas {
    if (_selectedEtapaId == null) return [];
    final etapa = _etapasTree.firstWhere((e) => e['id'] == _selectedEtapaId, orElse: () => {});
    return (etapa['manzanas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }
  
  List<Map<String, dynamic>> get _casas {
    if (_selectedManzanaId == null) return [];
    final manzanasList = _manzanas;
    final manzana = manzanasList.firstWhere((m) => m['id'] == _selectedManzanaId, orElse: () => {});
    return (manzana['casas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Propietario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Personal',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(label: 'Nombre completo', icon: Icons.person_outline_rounded, controller: _nombreCtrl),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(label: 'Teléfono', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, controller: _telefonoCtrl),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(label: 'Correo electrónico (Opcional)', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, controller: _emailCtrl),
            
            const SizedBox(height: AppSpacing.md),
            _buildDropdown(
              label: 'Modalidad de Pago',
              icon: Icons.calendar_today_outlined,
              value: _modalidadPago,
              items: [
                {'id': 'MENSUAL', 'nombre': 'Mensual'},
                {'id': 'QUINCENAL', 'nombre': 'Quincenal'},
                {'id': 'SEMANAL', 'nombre': 'Semanal'},
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _modalidadPago = val);
                }
              },
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Asignación de Inmueble',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Seleccione la ubicación en la estructura del proyecto.',
              style: AppTypography.small.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Selector de Etapa
            _buildDropdown(
              label: 'Etapa',
              icon: Icons.account_tree_outlined,
              value: _selectedEtapaId,
              items: _etapas,
              onChanged: (val) {
                setState(() {
                  _selectedEtapaId = val;
                  _selectedEtapaName = _etapas.firstWhere((e) => e['id'] == val)['nombre'];
                  _selectedManzanaId = null;
                  _selectedCasaId = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Selector de Manzana (Depende de Etapa)
            _buildDropdown(
              label: 'Manzana',
              icon: Icons.grid_view_rounded,
              value: _selectedManzanaId,
              items: _manzanas,
              enabled: _selectedEtapaId != null,
              onChanged: (val) {
                setState(() {
                  _selectedManzanaId = val;
                  _selectedManzanaName = _manzanas.firstWhere((m) => m['id'] == val)['nombre'];
                  _selectedCasaId = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Selector de Casa (Depende de Manzana)
            _buildDropdown(
              label: 'Lote / Casa',
              icon: Icons.home_outlined,
              value: _selectedCasaId,
              items: _casas,
              enabled: _selectedManzanaId != null,
              onChanged: (val) {
                setState(() {
                  _selectedCasaId = val;
                  _selectedCasaName = _casas.firstWhere((c) => c['id'] == val)['nombre'];
                });
              },
            ),
            
            // Indicador visual de selección exitosa
            if (_selectedCasaId != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '$_selectedEtapaName - $_selectedManzanaName - $_selectedCasaName asignada correctamente.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : () async {
                  if (_nombreCtrl.text.isEmpty || _telefonoCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, ingrese al menos el nombre y teléfono.')),
                    );
                    return;
                  }
                  
                  setState(() => _isSaving = true);
                  try {
                    await _propietariosRepo.createPropietario(
                      nombre: _nombreCtrl.text,
                      telefono: _telefonoCtrl.text,
                      email: _emailCtrl.text,
                      casaId: _selectedCasaId,
                      modalidadPago: _modalidadPago,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Propietario creado con éxito.')),
                      );
                      context.pop(true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear propietario: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                },
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear Propietario'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textDisabled),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['id'].toString(),
          child: Text(item['nombre'].toString()),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? AppColors.textDisabled : AppColors.textDisabled.withValues(alpha: 0.3)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
      ),
      icon: Icon(Icons.arrow_drop_down_rounded, color: enabled ? AppColors.textSecondary : AppColors.textDisabled.withValues(alpha: 0.3)),
      isExpanded: true,
      menuMaxHeight: 300,
      hint: Text(
        'Selecciona $label',
        style: AppTypography.body.copyWith(
          color: enabled ? AppColors.textDisabled : AppColors.textDisabled.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
