import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/registro.dart';
import 'registro_repository.dart';

class SupabaseRegistroRepository implements RegistroRepository {
  SupabaseRegistroRepository(this.client);

  final SupabaseClient client;

  String get _userId {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('No existe una sesion autenticada.');
    }
    return user.id;
  }

  @override
  Future<List<Registro>> fetchAll() async {
    final rows = await client
        .from('registros_demo')
        .select()
        .order('created_at', ascending: false);

    return rows.map(Registro.fromMap).toList();
  }

  @override
  Future<void> create(Registro registro) async {
    await client.from('registros_demo').insert(registro.toInsertMap(_userId));
  }

  @override
  Future<void> update(Registro registro) async {
    final id = registro.id;
    if (id == null) {
      throw ArgumentError('El registro no tiene id.');
    }

    await client
        .from('registros_demo')
        .update(registro.toUpdateMap())
        .eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await client.from('registros_demo').delete().eq('id', id);
  }
}
