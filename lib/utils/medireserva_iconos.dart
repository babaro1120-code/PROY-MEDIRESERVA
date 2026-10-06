import 'package:flutter/material.dart';

/// Catálogo de iconos que el administrador puede asignar a una especialidad.
///
/// Los nombres son los que guarda la columna `specialties.icon_name` y son los
/// mismos que ya interpreta el catálogo del paciente
/// (`lib/screens/specialties_screen.dart`). Se mantiene acá para que el panel
/// ofrezca exactamente los iconos que la app sabe dibujar.
const List<String> nombresDeIconos = [
  'medical_services',
  'child_care',
  'favorite',
  'face',
  'pregnant_woman',
  'dentistry',
  'visibility',
  'psychology',
  'healing',
  'biotech',
];

/// Traduce `specialties.icon_name` a un icono de Material.
IconData iconoDeEspecialidad(String? nombre) => switch (nombre) {
      'child_care' => Icons.child_care_outlined,
      'favorite' => Icons.favorite,
      'face' => Icons.face_outlined,
      'pregnant_woman' => Icons.pregnant_woman_outlined,
      'dentistry' => Icons.health_and_safety_outlined,
      'visibility' => Icons.visibility_outlined,
      'psychology' => Icons.psychology_outlined,
      'healing' => Icons.healing_outlined,
      'biotech' => Icons.biotech_outlined,
      _ => Icons.medical_services_outlined,
    };

/// Etiqueta legible de cada icono para el selector del panel.
String etiquetaDeIcono(String nombre) => switch (nombre) {
      'medical_services' => 'Medicina general',
      'child_care' => 'Pediatría',
      'favorite' => 'Cardiología',
      'face' => 'Dermatología',
      'pregnant_woman' => 'Ginecología',
      'dentistry' => 'Odontología',
      'visibility' => 'Oftalmología',
      'psychology' => 'Psicología',
      'healing' => 'Terapias',
      'biotech' => 'Laboratorio',
      _ => nombre,
    };
