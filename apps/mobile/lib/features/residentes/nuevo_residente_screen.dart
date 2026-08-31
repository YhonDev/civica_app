import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import 'comunidad_repository.dart';
import 'residentes_repository.dart';

/// Resultado de la creación del residente (lo que devuelve el backend).
class _ResultadoCrearResidente {
  final String username;
  final String password;
  final String nombre;

  const _ResultadoCrearResidente({
    required this.username,
    required this.password,
    required this.nombre,
  });
}

class NuevoResidenteScreen extends StatefulWidget {
  const NuevoResidenteScreen({super.key});

  @override
  State<NuevoResidenteScreen> createState() => _NuevoResidenteScreenState();
}

class _NuevoResidenteScreenState extends State<NuevoResidenteScreen> {
  final ComunidadRepository _comunidadRepo = ComunidadRepository();
  final ResidentesRepository _residentesRepo = ResidentesRepository();
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

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty || _telefonoCtrl.text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese al menos el nombre y teléfono.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = await _residentesRepo.createResidente(
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        casaId: _selectedCasaId,
        modalidadPago: _modalidadPago,
      );

      final credenciales = data['credenciales'] as Map<String, dynamic>?;
      final usuario = data['usuario'] as Map<String, dynamic>?;

      if (!context.mounted) return;

      _mostrarCredenciales(_ResultadoCrearResidente(
        username: credenciales?['username'] as String? ?? '',
        password: credenciales?['password'] as String? ?? '',
        nombre: usuario?['nombre'] as String? ?? _nombreCtrl.text.trim(),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear residente: $e')),
      );
    } finally {
      if (context.mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _mostrarCredenciales(_ResultadoCrearResidente resultado) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Residente creado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${resultado.nombre} ha sido registrado correctamente.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Usuario:', style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    resultado.username,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Contraseña:', style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    resultado.password,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Guarda estas credenciales. No se mostrarán nuevamente.',
              style: AppTypography.small.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Usuario: ${resultado.username}\nContraseña: ${resultado.password}',
              ));
              TopToast.showSuccess(ctx, 'Credenciales copiadas al portapapeles');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar Credenciales'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(true);
            },
            child: const Text('Listo'),
          ),
        ],
      ),
    );
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
    final list = (etapa['manzanas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return List<Map<String, dynamic>>.from(list)
      ..sort((a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));
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
        title: const Text('Nuevo Residente'),
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
            
            // Indicador visual de selección de inmueble
            if (_selectedCasaId != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Inmueble seleccionado: $_selectedEtapaName - $_selectedManzanaName - $_selectedCasaName',
                          style: AppTypography.body.copyWith(
                            color: AppColors.info,
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
                onPressed: _isSaving ? null : _guardar,
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear Residente'),
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
      autofillHints: null,
      enableSuggestions: false,
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
      key: ValueKey('${label}_$value'),
      initialValue: value,
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
