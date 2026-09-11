import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../shared/widgets/credentials_dialog.dart';
import 'comunidad_repository.dart';

class _ResultadoCrearCobrador {
  final String username;
  final String password;
  final String nombre;

  const _ResultadoCrearCobrador({
    required this.username,
    required this.password,
    required this.nombre,
  });
}

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

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
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
    if (_nombreCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      TopToast.showError(context, 'El nombre del cobrador es obligatorio');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'nombre': _nombreCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
      };

      if (_selectedEtapaId != null) {
        payload['etapaIds'] = <String>[_selectedEtapaId!];
      }

      final response = await _api.post<Map<String, dynamic>>(
        '/cobradores',
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      final credenciales = data['credenciales'] as Map<String, dynamic>?;
      final usuario = data['usuario'] as Map<String, dynamic>?;

      if (!mounted) return;

      _mostrarCredenciales(_ResultadoCrearCobrador(
        username: credenciales?['username'] as String? ?? '',
        password: credenciales?['password'] as String? ?? '',
        nombre: usuario?['nombre'] as String? ?? _nombreCtrl.text.trim(),
      ));
    } catch (e) {
      if (!mounted) return;
      TopToast.showError(context, e, prefix: 'Error al crear cobrador');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _mostrarCredenciales(_ResultadoCrearCobrador resultado) {
    CredentialsDialog.show(
      context: context,
      title: 'Cobrador creado',
      nombre: resultado.nombre,
      username: resultado.username,
      password: resultado.password,
      onDismiss: () => context.pop(true),
    );
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'El backend generará automáticamente el usuario y contraseña para el inicio de sesión.',
                    style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    label: 'Nombre completo',
                    icon: Icons.person_outline_rounded,
                    controller: _nombreCtrl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    label: 'Teléfono (opcional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    controller: _telefonoCtrl,
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
                      setState(() => _selectedEtapaId = val);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _guardar,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Guardando...' : 'Guardar Cobrador'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.info,
                      ),
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
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
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
        style: AppTypography.body.copyWith(color: AppColors.textDisabled),
      ),
    );
  }
}
