import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'comunidad_repository.dart';

class NuevoCobradorScreen extends StatefulWidget {
  const NuevoCobradorScreen({super.key});

  @override
  State<NuevoCobradorScreen> createState() => _NuevoCobradorScreenState();
}

class _NuevoCobradorScreenState extends State<NuevoCobradorScreen> {
  final ComunidadRepository _repo = ComunidadRepository();
  final ApiClient _api = ApiClient.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _etapasTree = [];
  String? _selectedEtapaId;
  String? _selectedEtapaName;

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

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
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTree() async {
    try {
      final tree = await _repo.getArbolCompleto();
      setState(() {
        _etapasTree = tree;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y correo son obligatorios')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Crear usuario con rol COBRADOR
      final response = await _api.post('/auth/register', data: {
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.isNotEmpty
            ? _passwordCtrl.text
            : 'cobrador123',
        'nombre': _nombreCtrl.text.trim(),
        'rol': 'COBRADOR',
        'tenantId': ComunidadRepository.currentTenantId,
      });

      final usuarioId = response.data['id'] as String? ?? response.data['usuario']?['id'] as String?;
      if (usuarioId == null) {
        throw Exception('No se pudo obtener el ID del usuario creado');
      }

      // 2. Asignar etapa si se seleccionó una
      if (_selectedEtapaId != null) {
        await _api.post('/usuarios/$usuarioId/etapas', data: {
          'etapaId': _selectedEtapaId,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobrador creado con éxito')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear cobrador: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Form(
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
                    _buildTextField(
                      label: 'Nombre completo',
                      icon: Icons.person_outline_rounded,
                      controller: _nombreCtrl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      label: 'Teléfono',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _telefonoCtrl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailCtrl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      label: 'Contraseña (opcional, default: cobrador123)',
                      icon: Icons.lock_outlined,
                      controller: _passwordCtrl,
                      obscureText: true,
                    ),

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
                      value: _selectedEtapaId,
                      items: _etapasTree,
                      onChanged: (val) {
                        setState(() {
                          _selectedEtapaId = val;
                          _selectedEtapaName = _etapasTree
                              .firstWhere((e) => e['id'] == val)['nombre'];
                        });
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _guardar,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.info,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar Cobrador'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextEditingController? controller,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['id'].toString(),
          child: Text(item['nombre'].toString()),
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
      menuMaxHeight: 300,
      hint: Text(
        'Selecciona $label',
        style: AppTypography.body.copyWith(
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
