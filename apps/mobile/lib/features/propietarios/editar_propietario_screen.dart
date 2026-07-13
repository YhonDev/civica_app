import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'comunidad_repository.dart';
import 'propietarios_repository.dart';
import 'models/propietarios_models.dart';

class EditarPropietarioScreen extends StatefulWidget {
  final PropietarioItem propietario;

  const EditarPropietarioScreen({super.key, required this.propietario});

  @override
  State<EditarPropietarioScreen> createState() => _EditarPropietarioScreenState();
}

class _EditarPropietarioScreenState extends State<EditarPropietarioScreen> {
  final ComunidadRepository _comunidadRepo = ComunidadRepository();
  final PropietariosRepository _propietariosRepo = PropietariosRepository();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _etapasTree = [];

  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;

  String? _selectedEtapaId;
  String? _selectedManzanaId;
  String? _selectedCasaId;

  String? _selectedEtapaName;
  String? _selectedManzanaName;
  String? _selectedCasaName;

  String _selectedModalidad = 'MENSUAL';

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.propietario.nombre);
    _telefonoCtrl = TextEditingController(text: widget.propietario.telefono);
    _emailCtrl = TextEditingController(text: widget.propietario.email ?? '');

    _selectedEtapaId = widget.propietario.etapaId;
    _selectedManzanaId = widget.propietario.manzanaId;
    _selectedCasaId = widget.propietario.casaId;

    // Use default if missing or invalid
    final validModalidades = ['MENSUAL', 'QUINCENAL', 'SEMANAL'];
    _selectedModalidad = validModalidades.contains(widget.propietario.modalidadPago) 
        ? widget.propietario.modalidadPago 
        : 'MENSUAL';

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
      final tree = await _comunidadRepo.getArbolCompleto(includeCasaId: widget.propietario.casaId);
      setState(() {
        _etapasTree = tree;
        _isLoading = false;

        // Recuperar nombres si hay datos precargados
        if (_selectedEtapaId != null) {
          final e = _etapas.firstWhere((e) => e['id'] == _selectedEtapaId, orElse: () => {});
          _selectedEtapaName = e['nombre'];
        }
        if (_selectedManzanaId != null) {
          final m = _manzanas.firstWhere((m) => m['id'] == _selectedManzanaId, orElse: () => {});
          _selectedManzanaName = m['nombre'];
        }
        if (_selectedCasaId != null) {
          final c = _casas.firstWhere((c) => c['id'] == _selectedCasaId, orElse: () => {});
          _selectedCasaName = c['nombre'];
        }
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
        title: const Text('Editar Propietario'),
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
            
            // Modalidad de Pago
            DropdownButtonFormField<String>(
              value: _selectedModalidad,
              items: const [
                DropdownMenuItem(value: 'MENSUAL', child: Text('Mensual')),
                DropdownMenuItem(value: 'QUINCENAL', child: Text('Quincenal')),
                DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedModalidad = val);
                }
              },
              decoration: InputDecoration(
                labelText: 'Modalidad de Pago',
                prefixIcon: Icon(Icons.payment_outlined, color: AppColors.textDisabled),
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
              icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
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
            if (_selectedCasaId != null && _selectedEtapaName != null && _selectedManzanaName != null && _selectedCasaName != null)
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
                          '$_selectedEtapaName - $_selectedManzanaName - $_selectedCasaName asignada.',
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
                    Map<String, dynamic> data = {
                      'nombre': _nombreCtrl.text,
                      'telefono': _telefonoCtrl.text,
                      'modalidadPago': _selectedModalidad,
                    };
                    if (_emailCtrl.text.isNotEmpty) data['email'] = _emailCtrl.text;
                    if (_selectedCasaId != null) data['casaId'] = _selectedCasaId;

                    final success = await _propietariosRepo.updatePropietario(widget.propietario.id, data);
                    
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Propietario actualizado con éxito.')),
                        );
                        context.pop(true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al actualizar propietario')),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al actualizar propietario: $e')),
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
                  : const Text('Guardar Cambios'),
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
    // Si el valor no existe en la lista (posible si no ha cargado bien o fue eliminado), limpiarlo
    if (value != null && items.isNotEmpty && !items.any((item) => item['id'].toString() == value)) {
      value = null;
    }

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
