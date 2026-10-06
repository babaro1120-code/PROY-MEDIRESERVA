import 'package:flutter/material.dart';

import 'medireserva_ui.dart';

/// Marco visual de las pantallas del panel de administración.
///
/// A diferencia de [MediReservaPage] —que fija 380 px de ancho porque está
/// pensada para el móvil—, esta página aprovecha todo el ancho de la ventana:
/// el contenido se centra con un tope de 1180 px y las tablas se expanden. En
/// pantallas angostas el encabezado y los botones se apilan solos.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.acciones = const <Widget>[],
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> acciones;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMediBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 700;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: EdgeInsets.all(compacto ? 10 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _encabezado(context, compacto),
                      SizedBox(height: compacto ? 10 : 16),
                      Expanded(
                        child: SingleChildScrollView(child: child),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context, bool compacto) {
    final titulo = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: kMediText,
          ),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0DA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: Color(0xFF8A4B00),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kMediDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: kMediMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );

    if (acciones.isEmpty) return titulo;

    final botones = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: acciones,
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titulo, const SizedBox(height: 10), botones],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titulo),
        const SizedBox(width: 12),
        botones,
      ],
    );
  }
}

/// Panel blanco con el borde suave que usa todo el sistema.
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFFE0E6EE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

/// Estado vacío o de error de una pantalla del panel.
///
/// Se usa para las dos cosas a propósito: en ambos casos el usuario necesita
/// leer un mensaje claro y, cuando corresponde, poder reintentar.
class AdminAviso extends StatelessWidget {
  const AdminAviso({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.onReintentar,
    this.textoReintentar = 'Reintentar',
    this.accion,
  });

  final String mensaje;
  final IconData icono;
  final VoidCallback? onReintentar;
  final String textoReintentar;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 12),
      child: Center(
        child: Column(
          children: [
            Icon(icono, color: kMediMuted, size: 40),
            const SizedBox(height: 10),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMediMuted, fontSize: 13, height: 1.4),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onReintentar,
                child: Text(textoReintentar),
              ),
            ],
            if (accion != null) ...[
              const SizedBox(height: 10),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Distintivo de estado: activo/inactivo, disponible/reservado/cerrado.
class AdminEstado extends StatelessWidget {
  const AdminEstado({
    super.key,
    required this.etiqueta,
    required this.texto,
    required this.fondo,
  });

  /// Constructor cómodo para los tres estados del sistema.
  factory AdminEstado.activo(bool activo) => activo
      ? const AdminEstado(
          etiqueta: 'Activo',
          texto: Color(0xFF138A4A),
          fondo: Color(0xFFDDF5E6),
        )
      : const AdminEstado(
          etiqueta: 'Inactivo',
          texto: Color(0xFFD32F2F),
          fondo: Color(0xFFFFE8EA),
        );

  final String etiqueta;
  final Color texto;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          color: texto,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Una columna de [AdminTabla]: etiqueta, ancho relativo o fijo.
class AdminColumna {
  const AdminColumna(this.etiqueta, {this.flex = 1, this.ancho});

  final String etiqueta;
  final int flex;

  /// Si se indica, la columna ocupa un ancho fijo en píxeles (acciones).
  final double? ancho;
}

/// Tabla simple de escritorio, sin dependencias nuevas.
///
/// El encabezado y las filas comparten los mismos anchos, así que las columnas
/// quedan alineadas. Cada fila recibe una celda por columna, en el mismo orden.
class AdminTabla extends StatelessWidget {
  const AdminTabla({super.key, required this.columnas, required this.filas});

  final List<AdminColumna> columnas;
  final List<List<Widget>> filas;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _fila(
            celdas: [
              for (final columna in columnas)
                Text(
                  columna.etiqueta,
                  style: const TextStyle(
                    color: kMediMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
            colorFondo: const Color(0xFFF7F9FC),
          ),
          const Divider(height: 1, color: Color(0xFFE9EDF3)),
          for (var i = 0; i < filas.length; i++) ...[
            _fila(celdas: filas[i]),
            if (i < filas.length - 1)
              const Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: Color(0xFFE9EDF3),
              ),
          ],
        ],
      ),
    );
  }

  Widget _fila({required List<Widget> celdas, Color? colorFondo}) {
    final children = <Widget>[];
    for (var i = 0; i < celdas.length; i++) {
      final columna = columnas[i];
      final celda = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Align(alignment: Alignment.centerLeft, child: celdas[i]),
      );
      children.add(
        columna.ancho == null
            ? Expanded(flex: columna.flex, child: celda)
            : SizedBox(width: columna.ancho, child: celda),
      );
    }

    return Container(
      color: colorFondo,
      child: Row(children: children),
    );
  }
}

/// Pregunta de confirmación antes de una acción que cambia o borra datos.
///
/// Devuelve `false` si el usuario cierra el diálogo sin elegir.
Future<bool> confirmarAdmin(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String confirmar = 'Confirmar',
  bool destructivo = true,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            confirmar,
            style: TextStyle(
              color: destructivo ? const Color(0xFFD32F2F) : kMediBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}

/// Ancho del contenido de un diálogo del panel.
///
/// Se calcula con el ancho real de la ventana en lugar de fijarlo: un formulario
/// de 480 px fijos desbordaría en una ventana angosta. El tope de 480 px es el
/// que aprovecha el escritorio.
double anchoDialogo(BuildContext context, {double deseado = 480}) {
  final pantalla = MediaQuery.sizeOf(context).width;
  if (pantalla >= deseado + 80) return deseado;

  final disponible = pantalla - 110;
  return disponible < 220 ? 220 : disponible;
}

/// Campo de texto del panel, con el mismo estilo en todos los formularios.
class AdminCampo extends StatelessWidget {
  const AdminCampo({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.icono,
    this.ayuda,
    this.lineas = 1,
    this.tipo = TextInputType.text,
    this.habilitado = true,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final IconData? icono;
  final String? ayuda;
  final int lineas;
  final TextInputType tipo;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controlador,
        enabled: habilitado,
        maxLines: lineas,
        keyboardType: tipo,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          helperMaxLines: 2,
          labelStyle: const TextStyle(fontSize: 13, color: kMediMuted),
          helperStyle: const TextStyle(fontSize: 11.5, color: kMediMuted),
          prefixIcon:
              icono == null ? null : Icon(icono, size: 20, color: kMediBlue),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
          ),
        ),
      ),
    );
  }
}
