class Specialty {
  const Specialty({required this.id, required this.name, this.iconName});

  final String id;
  final String name;
  final String? iconName;

  factory Specialty.fromMap(Map<String, dynamic> map) {
    return Specialty(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      iconName: map['icon_name'] as String?,
    );
  }
}

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialtyId,
    this.specialtyName,
    this.photoUrl,
    this.experienceYears = 0,
    this.rating = 0,
  });

  final String id;
  final String name;
  final String specialtyId;
  final String? specialtyName;
  final String? photoUrl;
  final int experienceYears;
  final double rating;

  factory Doctor.fromMap(Map<String, dynamic> map) {
    final specialty = map['specialties'];
    return Doctor(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      specialtyId: map['specialty_id'].toString(),
      specialtyName: specialty is Map
          ? specialty['name'] as String?
          : null,
      photoUrl: map['photo_url'] as String?,
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.specialty,
    required this.doctor,
    required this.date,
    required this.time,
    required this.status,
    this.reservationNumber,
  });

  final String id;
  final String specialty;
  final String doctor;
  final DateTime date;
  final String time;
  final String status;
  final String? reservationNumber;

  factory Appointment.fromMap(Map<String, dynamic> map) {
    final specialty = map['specialties'];
    final doctor = map['doctors'];

    return Appointment(
      id: map['id'].toString(),
      specialty: specialty is Map
          ? specialty['name'] as String? ?? ''
          : '',
      doctor: doctor is Map ? doctor['name'] as String? ?? '' : '',
      date: DateTime.parse(map['appointment_date'].toString()),
      time: map['appointment_time'].toString(),
      status: map['status'] as String? ?? 'pending',
      reservationNumber: map['reservation_number'] as String?,
    );
  }
}
