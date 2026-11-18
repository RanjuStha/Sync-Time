
class ClientPerson {
  final int id;
  final String code;
  final String fullName;
  final String image;
  final String type; // ClientUser / Employee / Executive
  final String? attendancePreferenceTitle;
  final int? userId;
  final List<ClientShift> shifts;
  final List<String> departments;

  ClientPerson({
    required this.id,
    required this.code,
    required this.fullName,
    required this.image,
    required this.type,
    this.attendancePreferenceTitle,
    this.userId,
    this.shifts = const [],
    this.departments = const [],
  });

  factory ClientPerson.fromJson(Map<String, dynamic> j) => ClientPerson(
    id: j['id'] as int,
    code: (j['code'] ?? '').toString(),
    fullName: (j['fullName'] ?? '').toString().trim(),
    image: (j['image'] ?? '').toString(),
    type: (j['type'] ?? '').toString(),
    attendancePreferenceTitle: j['attendancePreferenceTitle'] as String?,
    userId: j['user_id'] as int?,
    shifts: ((j['shift'] as List?) ?? [])
        .map((e) => ClientShift.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    departments: ((j['departments'] as List?) ?? [])
        .map((e) => (e['value'] ?? '').toString())
        .toList(),
  );
}

class ClientShift {
  final String name, start, end;
  final Map<String, int> workingDays;

  ClientShift({
    required this.name,
    required this.start,
    required this.end,
    required this.workingDays,
  });

  factory ClientShift.fromJson(Map<String, dynamic> j) => ClientShift(
    name: (j['shift_name'] ?? '').toString(),
    start: (j['shift_start'] ?? '').toString(),
    end: (j['shift_end'] ?? '').toString(),
    workingDays: Map<String, int>.from(j['working_days'] ?? {}),
  );
}