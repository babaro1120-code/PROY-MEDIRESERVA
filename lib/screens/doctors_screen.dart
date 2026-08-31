import 'package:flutter/material.dart';
import 'appointment_datetime_screen.dart';

class Doctor {
  final String name;
  final String specialty;
  final double rating;
  final int experience;
  final String avatar;

  const Doctor({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.experience,
    required this.avatar,
  });
}

class DoctorsScreen extends StatelessWidget {
  final String specialty;

  const DoctorsScreen({
    super.key,
    required this.specialty,
  });

  List<Doctor> _doctors(String specialty) {
    switch (specialty) {
      case "Cardiología":
        return const [
          Doctor(
            name: "Dr. Andrés Torres",
            specialty: "Cardiología",
            rating: 4.9,
            experience: 12,
            avatar: "👨🏻‍⚕️",
          ),
          Doctor(
            name: "Dra. María Castro",
            specialty: "Cardiología",
            rating: 4.8,
            experience: 10,
            avatar: "👩🏻‍⚕️",
          ),
          Doctor(
            name: "Dr. Luis Herrera",
            specialty: "Cardiología",
            rating: 4.7,
            experience: 8,
            avatar: "👨🏻‍⚕️",
          ),
        ];

      case "Pediatría":
        return const [
          Doctor(
            name: "Dra. Sofía López",
            specialty: "Pediatría",
            rating: 4.9,
            experience: 11,
            avatar: "👩🏻‍⚕️",
          ),
          Doctor(
            name: "Dr. Miguel Ruiz",
            specialty: "Pediatría",
            rating: 4.8,
            experience: 9,
            avatar: "👨🏻‍⚕️",
          ),
        ];

      default:
        return [
          Doctor(
            name: "Dra. Ana López",
            specialty: specialty,
            rating: 4.9,
            experience: 7,
            avatar: "👩🏻‍⚕️",
          ),
          Doctor(
            name: "Dr. Juan Pérez",
            specialty: specialty,
            rating: 4.8,
            experience: 6,
            avatar: "👨🏻‍⚕️",
          ),
          Doctor(
            name: "Dra. Laura Gómez",
            specialty: specialty,
            rating: 4.7,
            experience: 5,
            avatar: "👩🏻‍⚕️",
          ),
          Doctor(
            name: "Dr. Carlos Méndez",
            specialty: specialty,
            rating: 4.6,
            experience: 8,
            avatar: "👨🏻‍⚕️",
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _doctors(specialty);

    return Scaffold(
      backgroundColor: const Color(0xffF5F8FC),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [

              Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const Spacer(),

                  Column(
                    children: const [

                      Text(
                        "Médicos disponibles",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff132C67),
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        "Paso 3 de 6",
                        style: TextStyle(
                          color: Color(0xff0A66FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 25),

              Expanded(
                child: ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (_, index) {

                    final doctor = doctors[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(

                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            doctor.avatar,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),

                        title: Text(
                          doctor.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [

                              Expanded(
                                child: Text(
                                  doctor.specialty,
                                ),
                              ),

                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 18,
                              ),

                              Text(
                                doctor.rating.toString(),
                              ),

                              const SizedBox(width: 14),

                              Text(
                                "${doctor.experience} años exp.",
                              ),
                            ],
                          ),
                        ),

                        trailing: const Icon(
                          Icons.chevron_right,
                        ),

                       onTap: () {

    Navigator.push(

        context,

        MaterialPageRoute(

            builder: (_) => AppointmentDateTimeScreen(

                doctorName: doctor.name,

                specialty: doctor.specialty,

            ),

        ),

    );
    },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}