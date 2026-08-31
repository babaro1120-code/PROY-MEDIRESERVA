import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Asegúrate de agregar esta dependencia en pubspec.yaml

class AppointmentDateTimeScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;

  const AppointmentDateTimeScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
  });

  @override
  State<AppointmentDateTimeScreen> createState() =>
      _AppointmentDateTimeScreenState();
}

class _AppointmentDateTimeScreenState
    extends State<AppointmentDateTimeScreen> {
  DateTime displayedMonth = DateTime(2025, 5);
  DateTime? selectedDate;
  String? selectedHour;

  final List<String> hours = [
    "08:00",
    "08:30",
    "09:00",
    "09:30",
    "10:00",
    "10:30",
    "11:00",
    "11:30",
    "14:00",
    "14:30",
    "15:00",
    "15:30",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: const [
                        Text(
                          "Selecciona una fecha",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff132C67),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Paso 4 de 6",
                          style: TextStyle(
                            color: Color(0xff1565FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 16),

              // Card del doctor
              Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xff1565FF),
                    child: Text(
                      widget.doctorName.isNotEmpty 
                          ? widget.doctorName[0].toUpperCase() 
                          : 'D',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(widget.doctorName),
                  subtitle: Text(widget.specialty),
                ),
              ),

              const SizedBox(height: 16),

              // Calendario
              TableCalendar(
                focusedDay: displayedMonth,
                firstDay: DateTime(2025),
                lastDay: DateTime(2030),
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDate, day);
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDate = selected;
                    displayedMonth = focused;
                  });
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xff1565FF),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Horarios disponibles
              const Text(
                "Horarios disponibles",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff132C67),
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: hours.map((hour) {
                  final selected = selectedHour == hour;
                  return ChoiceChip(
                    label: Text(hour),
                    selected: selected,
                    selectedColor: const Color(0xff1565FF),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedHour = hour;
                      });
                    },
                  );
                }).toList(),
              ),

              const Spacer(),

              // Botón Continuar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1565FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: selectedDate == null || selectedHour == null
                      ? null
                      : () {
                          // Navegar a la siguiente pantalla
                          print('Fecha seleccionada: $selectedDate');
                          print('Hora seleccionada: $selectedHour');
                          // Aquí puedes navegar a la siguiente pantalla
                        },
                  child: const Text(
                    "Continuar",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}