import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/mock_data.dart';

class NuevoPropietarioScreen extends StatefulWidget {
  const NuevoPropietarioScreen({super.key});

  @override
  State<NuevoPropietarioScreen> createState() => _NuevoPropietarioScreenState();
}

class _NuevoPropietarioScreenState extends State<NuevoPropietarioScreen> {
  String? _selectedEtapa;
  String? _selectedManzana;
  String? _selectedCasa;

  List<String> get _etapas => MockData.etapas;
  
  List<String> get _manzanas {
    if (_selectedEtapa == null) return [];
    return MockData.manzanasPorEtapa[_selectedEtapa!] ?? [];
  }
  
  List<String> get _casas {
    if (_selectedEtapa == null || _selectedManzana == null) return [];
    // Nota: en MockData actual, casasPorManzana solo usa la manzana como key.
    return MockData.casasPorManzana[_selectedManzana!] ?? [];
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
      body: SingleChildScrollView(
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
            _buildTextField(label: 'Nombre completo', icon: Icons.person_outline_rounded),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(label: 'Teléfono', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            
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
              value: _selectedEtapa,
              items: _etapas,
              onChanged: (val) {
                setState(() {
                  _selectedEtapa = val;
                  _selectedManzana = null;
                  _selectedCasa = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Selector de Manzana (Depende de Etapa)
            _buildDropdown(
              label: 'Manzana',
              icon: Icons.grid_view_rounded,
              value: _selectedManzana,
              items: _manzanas,
              enabled: _selectedEtapa != null,
              onChanged: (val) {
                setState(() {
                  _selectedManzana = val;
                  _selectedCasa = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Selector de Casa (Depende de Manzana)
            _buildDropdown(
              label: 'Lote / Casa',
              icon: Icons.home_outlined,
              value: _selectedCasa,
              items: _casas,
              enabled: _selectedManzana != null,
              onChanged: (val) {
                setState(() {
                  _selectedCasa = val;
                });
              },
            ),
            
            // Indicador visual de selección exitosa
            if (_selectedCasa != null)
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
                          '$_selectedEtapa - $_selectedManzana - $_selectedCasa asignada correctamente.',
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
                onPressed: _selectedCasa == null ? null : () {
                  context.pop();
                },
                child: const Text('Crear Propietario'),
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
  }) {
    return TextField(
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
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
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
      hint: Text(
        'Selecciona $label',
        style: AppTypography.body.copyWith(
          color: enabled ? AppColors.textDisabled : AppColors.textDisabled.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
