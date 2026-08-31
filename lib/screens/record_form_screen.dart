import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/context_snapshot.dart';
import '../models/registro.dart';
import '../repositories/registro_repository.dart';
import '../widgets/context_card.dart';
import '../widgets/max_width_box.dart';

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, this.initial, this.initialContext});

  final Registro? initial;
  final ContextSnapshot? initialContext;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late String _status;
  ContextSnapshot? _contextSnapshot;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initial?.titulo ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initial?.descripcion ?? '',
    );
    _status = widget.initial?.estado ?? 'activo';
    _contextSnapshot = widget.initialContext ?? widget.initial?.contexto;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      final repository = context.read<RegistroRepository>();

      final registro = Registro(
        id: widget.initial?.id,
        titulo: _titleController.text,
        descripcion: _descriptionController.text,
        estado: _status,
        createdAt: widget.initial?.createdAt,
        contexto: _contextSnapshot,
      );

      if (widget.initial == null) {
        await repository.create(registro);
      } else {
        await repository.update(registro);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Nuevo registro' : 'Editar registro',
        ),
      ),
      body: MaxWidthBox(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titulo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) {
                    return 'Minimo 3 caracteres';
                  }
                  if (text.length > 80) {
                    return 'Maximo 80 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: 'pendiente',
                    child: Text('Pendiente'),
                  ),
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'cerrado', child: Text('Cerrado')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              if (_contextSnapshot != null)
                ContextCard(snapshot: _contextSnapshot!)
              else
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Sin contexto externo. Puedes crear el registro '
                      'normalmente o venir desde Conexion con el mundo.',
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_busy ? 'Guardando...' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
