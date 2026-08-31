import 'package:flutter/material.dart';
import 'doctors_screen.dart';

class SpecialtiesScreen extends StatelessWidget {
  const SpecialtiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final specialties = [
      _Specialty(
        name: 'Medicina General',
        icon: Icons.medical_services_outlined,
      ),
      _Specialty(
        name: 'Pediatría',
        icon: Icons.child_care_outlined,
      ),
      _Specialty(
        name: 'Cardiología',
        icon: Icons.favorite,
      ),
      _Specialty(
        name: 'Dermatología',
        icon: Icons.accessibility_new_outlined,
      ),
      _Specialty(
        name: 'Ginecología',
        icon: Icons.health_and_safety_outlined,
      ),
      _Specialty(
        name: 'Odontología',
        icon: Icons.health_and_safety_outlined,
      ),
      _Specialty(
        name: 'Oftalmología',
        icon: Icons.visibility_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 360,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Column(
                  children: [

                    // ==================================================
                    // ENCABEZADO
                    // ==================================================

                    SizedBox(
                      height: 38,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [

                          // Botón regresar
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 18,
                                color: Color(0xFF172A4D),
                              ),
                            ),
                          ),

                          // Título
                          const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                'Especialidades',
                                style: TextStyle(
                                  color: Color(0xFF122B6B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Paso 2 de 6',
                                style: TextStyle(
                                  color: Color(0xFF075BD8),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 3),

                    // ==================================================
                    // LISTA DE ESPECIALIDADES
                    // ==================================================

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE1E7F0),
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Column(
                        children: List.generate(
                          specialties.length,
                          (index) {
                            final specialty =
                                specialties[index];

                            return _SpecialtyItem(
                              specialty: specialty,
                              showDivider:
                                  index != specialties.length - 1,
                              onTap: () {
                                _selectSpecialty(
                                  context,
                                  specialty.name,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SELECCIONAR ESPECIALIDAD
  // ================================================================

  void _selectSpecialty(
  BuildContext context,
  String specialty,
) {

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DoctorsScreen(
        specialty: specialty,
      ),
    ),
  );


    // Posteriormente aquí conectaremos:
    //
    // Especialidad
    //      ↓
    // Seleccionar Médico
    //
    // Navigator.push(...)
  }
}

// ==================================================================
// MODELO DE ESPECIALIDAD
// ==================================================================

class _Specialty {
  const _Specialty({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

// ==================================================================
// ITEM DE ESPECIALIDAD
// ==================================================================

class _SpecialtyItem extends StatelessWidget {
  const _SpecialtyItem({
    required this.specialty,
    required this.showDivider,
    required this.onTap,
  });

  final _Specialty specialty;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),

          child: SizedBox(
            height: 33,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
              ),
              child: Row(
                children: [

                  // --------------------------------------------------
                  // ICONO
                  // --------------------------------------------------

                  SizedBox(
                    width: 25,
                    child: Icon(
                      specialty.icon,
                      color: const Color(0xFF075BD8),
                      size: 17,
                    ),
                  ),

                  const SizedBox(width: 5),

                  // --------------------------------------------------
                  // NOMBRE
                  // --------------------------------------------------

                  Expanded(
                    child: Text(
                      specialty.name,
                      style: const TextStyle(
                        color: Color(0xFF16284A),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // --------------------------------------------------
                  // FLECHA
                  // --------------------------------------------------

                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF65748A),
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ------------------------------------------------------------
        // SEPARADOR
        // ------------------------------------------------------------

        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.7,
            indent: 9,
            endIndent: 9,
            color: Color(0xFFE8EDF4),
          ),
      ],
    );
  }
}