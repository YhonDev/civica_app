import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/mock_data.dart';

class NuevoCobradorScreen extends StatefulWidget {
  const NuevoCobradorScreen({super.key});

  @override
  State<NuevoCobradorScreen> createState() => _NuevoCobradorScreenState();
}

class _NuevoCobradorScreenState extends State<NuevoCobradorScreen> {
  String? _selectedEtapa;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Cobrador'),
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
            const SizedBox(height: AppSpacing.md),
            _buildTextField(label: 'Correo electrónico', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Asignación de Zonas',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDropdown(
              label: 'Zona asignada (Etapa)',
              icon: Icons.map_outlined,
              value: _selectedEtapa,
              items: MockData.etapas,
              onChanged: (val) {
                setState(() => _selectedEtapa = val);
              },
            ),
            
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // TODO: Save logic
                  context.pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.info,
                ),
                child: const Text('Guardar Cobrador'),
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
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
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
      icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
      isExpanded: true,
      hint: Text(
        'Selecciona $label',
        style: AppTypography.body.copyWith(
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
