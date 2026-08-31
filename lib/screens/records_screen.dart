import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/registro.dart';
import '../repositories/registro_repository.dart';
import '../widgets/max_width_box.dart';
import 'record_form_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  bool _loading = true;
  String? _error;
  List<Registro> _items = const <Registro>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await context.read<RegistroRepository>().fetchAll();
      if (mounted) {
        setState(() => _items = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openForm([Registro? item]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (routeContext) => RecordFormScreen(initial: item),
      ),
    );

    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete(Registro item) async {
    final id = item.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar registro'),
          content: Text('Eliminar "${item.titulo}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<RegistroRepository>().delete(id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis registros')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: MaxWidthBox(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 52),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const <Widget>[
            SizedBox(height: 180),
            Center(child: Text('Todavia no hay registros.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          final contextText = item.contexto == null
              ? 'sin contexto'
              : '${item.contexto!.weather.temperatureC.toStringAsFixed(1)} C - '
                    '${item.contexto!.weather.summary}';

          final description = item.descripcion.isEmpty
              ? 'Sin descripcion'
              : item.descripcion;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  item.contexto == null
                      ? Icons.description_outlined
                      : Icons.location_on_outlined,
                ),
              ),
              title: Text(
                item.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${item.estado} - $contextText\n$description'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openForm(item);
                  } else if (value == 'delete') {
                    _delete(item);
                  }
                },
                itemBuilder: (menuContext) {
                  return const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ];
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
