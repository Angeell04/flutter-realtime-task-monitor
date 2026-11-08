import 'package:app/models/tarea_model.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/services/tarea_service.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tareas Antigravity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 32, 35, 41),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Tarea>> futureTareas;
  String _criterioOrden = 'recientes';

  @override
  void initState() {
    super.initState();
    futureTareas = getTareas();

    iniciarEscuchaEnTiempoReal(
      onNuevaTarea: (Tarea tarea) {
        final bool esError = tarea.estado.toLowerCase() == 'error' ||
            tarea.estado.toLowerCase() == 'fallido';
        final String icono = esError ? '❌' : '✅';
        final String tituloNotificacion =
            '$icono Tarea ${pintaEstado(tarea.estado)}: ${tarea.titulo}';
        final String cuerpoNotificacion =
            'Duración: ${tarea.duracion}\n${tarea.resumen}';

        NotificationService.mostrarNotificacion(
          titulo: tituloNotificacion,
          cuerpo: cuerpoNotificacion,
          payload: tarea.id,
        );
      },
      onActualizarLista: () {
        if (mounted) {
          setState(() {
            futureTareas = getTareas();
          });
        }
      },
    );
  }

  void _recargarTareas() {
    setState(() {
      futureTareas = getTareas();
    });
  }

  List<Tarea> _ordenarTareas(List<Tarea> lista) {
    final List<Tarea> resultado = List<Tarea>.from(lista);

    switch (_criterioOrden) {
      case 'recientes':
        resultado.sort((a, b) {
          if (a.timestamp > 0 && b.timestamp > 0) {
            return b.timestamp.compareTo(a.timestamp);
          }
          if (a.id != null && b.id != null) {
            return b.id!.compareTo(a.id!);
          }
          return 0;
        });
        break;
      case 'antiguos':
        resultado.sort((a, b) {
          if (a.timestamp > 0 && b.timestamp > 0) {
            return a.timestamp.compareTo(b.timestamp);
          }
          if (a.id != null && b.id != null) {
            return a.id!.compareTo(b.id!);
          }
          return 0;
        });
        break;
      case 'errores':
        resultado.sort((a, b) {
          final aEsError = a.estado.toLowerCase() == 'error' ? 0 : 1;
          final bEsError = b.estado.toLowerCase() == 'error' ? 0 : 1;
          return aEsError.compareTo(bEsError);
        });
        break;
      case 'alfabetico':
        resultado.sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
        break;
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 32, 35, 41),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 87, 255),
        title: const Text('Tareas Antigravity'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        elevation: 10,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Ordenar tareas',
            initialValue: _criterioOrden,
            onSelected: (String valor) {
              setState(() {
                _criterioOrden = valor;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'recientes',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Color.fromARGB(255, 57, 255, 20)),
                    SizedBox(width: 10),
                    Text('Más recientes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'antiguos',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.white70),
                    SizedBox(width: 10),
                    Text('Más antiguos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'errores',
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Color.fromARGB(255, 214, 61, 46)),
                    SizedBox(width: 10),
                    Text('Errores primero'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'alfabetico',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, color: Color.fromARGB(255, 0, 181, 204)),
                    SizedBox(width: 10),
                    Text('Alfabético (A-Z)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recargar',
            onPressed: _recargarTareas,
          ),
        ],
      ),
      body: FutureBuilder<List<Tarea>>(
        future: futureTareas,
        builder: (context, AsyncSnapshot<List<Tarea>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 57, 255, 20),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color.fromARGB(255, 214, 61, 46),
                      size: 60,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se han podido cargar los datos de Firebase',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 57, 255, 20),
                        foregroundColor: const Color.fromARGB(255, 32, 35, 41),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _recargarTareas,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final tareas = _ordenarTareas(snapshot.data ?? []);
          if (tareas.isEmpty) {
            return const Center(
              child: Text(
                'No hay tareas registradas en Firebase',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return PintaTareas(tareas: tareas);
        },
      ),
    );
  }
}

class PintaTareas extends StatefulWidget {
  final dynamic tareas;

  const PintaTareas({super.key, required this.tareas});

  @override
  State<PintaTareas> createState() => _PintaTareasState();
}

class _PintaTareasState extends State<PintaTareas> {
  int tareaAPintar = -1;

  @override
  Widget build(BuildContext context) {
    return (tareaAPintar == -1)
        ? _pintaLista(tareas: widget.tareas)
        : _pintaDetalleTarea(index: tareaAPintar, tareas: widget.tareas);
  }

  Widget _pintaLista({required dynamic tareas}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      itemCount: widget.tareas.length,
      itemBuilder: (BuildContext context, int index) {
        final Tarea tarea = widget.tareas[index];
        final Color colorActual = colorEstado(tarea.estado);

        return Card(
          color: const Color.fromARGB(255, 44, 48, 56),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorActual.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: colorActual,
              child: Icon(
                iconoEstado(tarea.estado),
                color: const Color.fromARGB(255, 32, 35, 41),
                size: 26,
              ),
            ),
            title: Text(
              tarea.titulo,
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 181, 204),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: colorActual.withValues(alpha: 0.2),
                      border: Border.all(color: colorActual, width: 1),
                    ),
                    child: Text(
                      'Estado: ${pintaEstado(tarea.estado)}',
                      style: TextStyle(
                        color: colorActual,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 32, 35, 41),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Color.fromARGB(255, 240, 225, 74),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tarea.duracion,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 240, 225, 74),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tarea.fecha.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromARGB(255, 32, 35, 41),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tarea.fecha,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                setState(() {
                  tareaAPintar = index;
                });
              },
              icon: const Icon(
                Icons.arrow_forward,
                color: Color.fromARGB(255, 57, 255, 20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pintaDetalleTarea({required int index, required dynamic tareas}) {
    final Tarea tarea = widget.tareas[index];
    final Color colorActual = colorEstado(tarea.estado);
    final bool tieneErrores = tarea.detallesErrores.isNotEmpty &&
        tarea.detallesErrores.toLowerCase() != 'ninguno' &&
        tarea.detallesErrores.toLowerCase() != 'sin errores';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 55,
            backgroundColor: colorActual.withValues(alpha: 0.2),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: colorActual,
              child: Icon(
                iconoEstado(tarea.estado),
                size: 45,
                color: const Color.fromARGB(255, 32, 35, 41),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tarea.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Color.fromARGB(255, 57, 255, 20),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colorActual.withValues(alpha: 0.2),
                  border: Border.all(color: colorActual, width: 1.5),
                ),
                child: Text(
                  'Estado: ${pintaEstado(tarea.estado)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorActual,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 44, 48, 56),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Color.fromARGB(255, 240, 225, 74),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Duración: ${tarea.duracion}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color.fromARGB(255, 240, 225, 74),
                      ),
                    ),
                  ],
                ),
              ),
              if (tarea.fecha.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(255, 44, 48, 56),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tarea.fecha,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 44, 48, 56),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromARGB(255, 0, 181, 204)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Color.fromARGB(255, 0, 181, 204),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Resumen',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 181, 204),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                Text(
                  tarea.resumen.isNotEmpty
                      ? tarea.resumen
                      : 'Sin descripción detallada.',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 44, 48, 56),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tieneErrores
                    ? const Color.fromARGB(255, 214, 61, 46)
                    : const Color.fromARGB(255, 57, 255, 20)
                        .withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      tieneErrores
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: tieneErrores
                          ? const Color.fromARGB(255, 214, 61, 46)
                          : const Color.fromARGB(255, 57, 255, 20),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Detalles de Errores',
                      style: TextStyle(
                        color: tieneErrores
                            ? const Color.fromARGB(255, 214, 61, 46)
                            : const Color.fromARGB(255, 57, 255, 20),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                Text(
                  tieneErrores
                      ? tarea.detallesErrores
                      : 'Ninguno. La tarea se completó sin errores.',
                  style: TextStyle(
                    color: tieneErrores
                        ? const Color.fromARGB(255, 255, 180, 180)
                        : Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          IconButton(
            onPressed: () {
              setState(() {
                tareaAPintar = -1;
              });
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromARGB(255, 57, 255, 20),
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

String pintaEstado(String estado) {
  switch (estado.toLowerCase()) {
    case 'terminado':
    case 'completado':
      return 'Terminado';
    case 'error':
    case 'fallido':
      return 'Error';
    case 'en_proceso':
    case 'ejecutando':
      return 'En proceso';
    default:
      return estado.isNotEmpty ? estado : 'Desconocido';
  }
}

Color colorEstado(String estado) {
  switch (estado.toLowerCase()) {
    case 'terminado':
    case 'completado':
      return const Color.fromARGB(255, 57, 255, 20);
    case 'error':
    case 'fallido':
      return const Color.fromARGB(255, 214, 61, 46);
    case 'en_proceso':
    case 'ejecutando':
      return const Color.fromARGB(255, 240, 225, 74);
    default:
      return const Color.fromARGB(255, 0, 181, 204);
  }
}

IconData iconoEstado(String estado) {
  switch (estado.toLowerCase()) {
    case 'terminado':
    case 'completado':
      return Icons.check_circle;
    case 'error':
    case 'fallido':
      return Icons.cancel;
    case 'en_proceso':
    case 'ejecutando':
      return Icons.hourglass_top;
    default:
      return Icons.info_outline;
  }
}
