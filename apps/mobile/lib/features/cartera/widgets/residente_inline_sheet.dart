import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/residente_dao.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../residentes/comunidad_repository.dart';
import '../../residentes/residentes_repository.dart';

class ResidenteInlineSheet extends StatefulWidget {
  final String? preselectedCasaId;
  final void Function(Map<String, dynamic> creado) onSuccess;

  const ResidenteInlineSheet({
    super.key,
    this.preselectedCasaId,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    String? preselectedCasaId,
    required void Function(Map<String, dynamic> creado) onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetRadius),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ResidenteInlineSheet(
          preselectedCasaId: preselectedCasaId,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<ResidenteInlineSheet> createState() => _ResidenteInlineSheetState();
}

class _ResidenteInlineSheetState extends State<ResidenteInlineSheet> {
  final ComunidadRepository _comunidadRepo = ComunidadRepository();
  final ResidentesRepository _residentesRepo = ResidentesRepository();
  final _formKey = GlobalKey<FormState>();

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
      final tree = await _comunidadRepo.getArbolCompleto(includeCasaId: widget.preselectedCasaId);
      setState(() {
        _etapasTree = tree;
        if (widget.preselectedCasaId != null) {
          for (final etapa in tree) {
            for (final manzana in (etapa['manzanas'] as List? ?? [])) {
              for (final casa in (manzana['casas'] as List? ?? [])) {
                if (casa['id'] == widget.preselectedCasaId) {
                  _selectedEtapaId = etapa['id'];
                  _selectedManzanaId = manzana['id'];
                  _selectedCasaId = casa['id'];
                  break;
                }
              }
            }
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar viviendas: $e')),
        );
      }
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = await _residentesRepo.createPropietario(
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        casaId: _selectedCasaId,
        modalidadPago: _modalidadPago,
      );

      final creado = data['usuario'] as Map<String, dynamic>?;
      if (creado != null) {
        try {
          final newResidente = ResidentesCompanion.insert(
            id: creado['id'] ?? '',
            nombre: creado['nombre'] ?? '',
            telefono: creado['telefono'] ?? '',
            email: Value(creado['email']),
            tenantId: creado['tenantId'] ?? '00000000-0000-0000-0000-000000000001',
            createdAt: creado['createdAt'] != null ? DateTime.parse(creado['createdAt']) : DateTime.now(),
            updatedAt: creado['updatedAt'] != null ? DateTime.parse(creado['updatedAt']) : DateTime.now(),
          );

          await ResidenteDao(AppDatabase.instance).insertConTenencia(
            residente: newResidente,
            casaId: _selectedCasaId!,
          );
        } catch (dbErr) {
          debugPrint('Error inserting resident locally: $dbErr');
        }
      }

      if (!mounted) return;

      Navigator.pop(context); // Close bottom sheet
      widget.onSuccess(data); // Propagate success
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear residente: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrar Residente',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico (Opcional)',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _modalidadPago,
                decoration: InputDecoration(
                  labelText: 'Modalidad de Pago',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal')),
                  DropdownMenuItem(value: 'QUINCENAL', child: Text('Quincenal')),
                  DropdownMenuItem(value: 'MENSUAL', child: Text('Mensual')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _modalidadPago = val);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedEtapaId,
                      decoration: InputDecoration(
                        labelText: 'Etapa',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Seleccione')),
                        ..._etapas.map((e) => DropdownMenuItem(value: e['id'] as String?, child: Text(e['nombre'] ?? ''))),
                      ],
                      validator: (val) => val == null ? 'Requerido' : null,
                      onChanged: widget.preselectedCasaId != null
                          ? null
                          : (val) {
                              setState(() {
                                _selectedEtapaId = val;
                                _selectedManzanaId = null;
                                _selectedCasaId = null;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedManzanaId,
                      decoration: InputDecoration(
                        labelText: 'Manzana',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Seleccione')),
                        ..._manzanas.map((m) => DropdownMenuItem(value: m['id'] as String?, child: Text(m['nombre'] ?? ''))),
                      ],
                      validator: (val) => val == null ? 'Requerido' : null,
                      onChanged: widget.preselectedCasaId != null
                          ? null
                          : (val) {
                              setState(() {
                                _selectedManzanaId = val;
                                _selectedCasaId = null;
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCasaId,
                decoration: InputDecoration(
                  labelText: 'Casa',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Seleccione')),
                  ..._casas.map((c) => DropdownMenuItem(value: c['id'] as String?, child: Text(c['nombre'] ?? ''))),
                ],
                validator: (val) => val == null ? 'Requerido' : null,
                onChanged: widget.preselectedCasaId != null
                    ? null
                    : (val) {
                        setState(() => _selectedCasaId = val);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
