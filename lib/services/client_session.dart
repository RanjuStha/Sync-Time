// Session store (holds the API data and does the lookup)
import 'package:flexyear/models/client_person.dart';

class ClientSession {
  ClientSession._();

  static Map<String, dynamic> clientDetail = {};
  static List<ClientPerson> _people = [];

  /// Pass the `data` map from the /client/access response.
  static void load(Map data) {
    clientDetail = Map<String, dynamic>.from(data['clientDetail'] ?? {});

    final users = (data['clientUsersDetail'] as List?) ?? [];
    final employees = (data['clientEmployeesDetail'] as List?) ?? [];

    _people = [...users, ...employees]
        .map((e) => ClientPerson.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.code.isNotEmpty) // many users have code: null
        .toList();
  }

  static ClientPerson? findByCode(String code) {
    final c = code.trim();
    if (c.isEmpty) return null;
    for (final p in _people) {
      if (p.code == c) return p;
    }
    return null;
  }
}