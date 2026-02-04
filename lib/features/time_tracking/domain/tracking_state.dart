import 'dart:convert';

/// Modelo de estado para tracking de actividades en frontend
/// Gestiona inicio, pausas, reanudaciones y finalización
class ActividadTrackingState {
  final int idActividad;
  final EstadoActividad estado;
  final DateTime? inicioActual; // Inicio del periodo actual en proceso
  final List<PeriodoTrabajo> periodos;
  final String? observaciones;

  ActividadTrackingState({
    required this.idActividad,
    required this.estado,
    this.inicioActual,
    required this.periodos,
    this.observaciones,
  });

  /// Tiempo total trabajado (suma de todos los periodos cerrados)
  Duration get tiempoTotalTrabajado {
    Duration total = Duration.zero;

    // Sumar todos los periodos cerrados
    for (var periodo in periodos) {
      if (periodo.duracion != null) {
        total += periodo.duracion!;
      }
    }

    // Si está en proceso, sumar el tiempo del periodo actual
    if (estado == EstadoActividad.enProceso && inicioActual != null) {
      total += DateTime.now().difference(inicioActual!);
    }

    return total;
  }

  /// Tiempo del periodo actual (solo si está en proceso)
  Duration? get tiempoActualPeriodo {
    if (estado == EstadoActividad.enProceso && inicioActual != null) {
      return DateTime.now().difference(inicioActual!);
    }
    return null;
  }

  /// Tiempo total en pausas
  Duration get tiempoTotalPausas {
    Duration total = Duration.zero;
    DateTime? ultimaHoraTrabajo;

    for (var periodo in periodos) {
      if (periodo.tipo == TipoEvento.inicio ||
          periodo.tipo == TipoEvento.reanudacion) {
        if (ultimaHoraTrabajo != null &&
            periodo.inicio.isAfter(ultimaHoraTrabajo)) {
          // Hay una pausa entre el último trabajo y este inicio/reanudación
          total += periodo.inicio.difference(ultimaHoraTrabajo);
        }
      }

      if (periodo.fin != null) {
        ultimaHoraTrabajo = periodo.fin;
      }
    }

    return total;
  }

  /// Cantidad de pausas realizadas
  int get cantidadPausas {
    return periodos.where((p) => p.tipo == TipoEvento.pausa).length;
  }

  /// Crea un estado inicial (no iniciado)
  factory ActividadTrackingState.inicial(int idActividad) {
    return ActividadTrackingState(
      idActividad: idActividad,
      estado: EstadoActividad.noIniciada,
      periodos: [],
    );
  }

  /// Inicia la actividad
  ActividadTrackingState iniciar() {
    if (estado != EstadoActividad.noIniciada) {
      throw StateError('Solo se puede iniciar una actividad no iniciada');
    }

    final ahora = DateTime.now();
    return ActividadTrackingState(
      idActividad: idActividad,
      estado: EstadoActividad.enProceso,
      inicioActual: ahora,
      periodos: [
        ...periodos,
        PeriodoTrabajo(
          inicio: ahora,
          tipo: TipoEvento.inicio,
        ),
      ],
      observaciones: observaciones,
    );
  }

  /// Pausa la actividad
  ActividadTrackingState pausar() {
    if (estado != EstadoActividad.enProceso) {
      throw StateError('Solo se puede pausar una actividad en proceso');
    }

    if (inicioActual == null) {
      throw StateError('No hay periodo actual para pausar');
    }

    // Validar duración mínima de 5 segundos
    final duracionActual = DateTime.now().difference(inicioActual!);
    if (duracionActual.inSeconds < 5) {
      throw StateError('El periodo debe tener al menos 5 segundos');
    }

    final ahora = DateTime.now();
    final nuevoPeriodos = List<PeriodoTrabajo>.from(periodos);

    // Cerrar el periodo actual
    final ultimoIndice = nuevoPeriodos.length - 1;
    nuevoPeriodos[ultimoIndice] = nuevoPeriodos[ultimoIndice].cerrar(ahora);

    // Agregar evento de pausa
    nuevoPeriodos.add(PeriodoTrabajo(
      inicio: ahora,
      tipo: TipoEvento.pausa,
    ));

    return ActividadTrackingState(
      idActividad: idActividad,
      estado: EstadoActividad.pausada,
      inicioActual: null,
      periodos: nuevoPeriodos,
      observaciones: observaciones,
    );
  }

  /// Reanuda la actividad
  ActividadTrackingState reanudar() {
    if (estado != EstadoActividad.pausada) {
      throw StateError('Solo se puede reanudar una actividad pausada');
    }

    final ahora = DateTime.now();
    return ActividadTrackingState(
      idActividad: idActividad,
      estado: EstadoActividad.enProceso,
      inicioActual: ahora,
      periodos: [
        ...periodos,
        PeriodoTrabajo(
          inicio: ahora,
          tipo: TipoEvento.reanudacion,
        ),
      ],
      observaciones: observaciones,
    );
  }

  /// Finaliza la actividad
  ActividadTrackingState finalizar({String? observacionesFinales}) {
    if (estado != EstadoActividad.enProceso &&
        estado != EstadoActividad.pausada) {
      throw StateError(
          'Solo se puede finalizar una actividad en proceso o pausada');
    }

    final ahora = DateTime.now();
    final nuevoPeriodos = List<PeriodoTrabajo>.from(periodos);

    // Si está en proceso, cerrar el periodo actual
    if (estado == EstadoActividad.enProceso && inicioActual != null) {
      final ultimoIndice = nuevoPeriodos.length - 1;
      nuevoPeriodos[ultimoIndice] = nuevoPeriodos[ultimoIndice].cerrar(ahora);
    }

    // Agregar evento de finalización
    nuevoPeriodos.add(PeriodoTrabajo(
      inicio: ahora,
      tipo: TipoEvento.finalizacion,
    ));

    return ActividadTrackingState(
      idActividad: idActividad,
      estado: EstadoActividad.finalizada,
      inicioActual: null,
      periodos: nuevoPeriodos,
      observaciones: observacionesFinales ?? observaciones,
    );
  }

  /// Actualiza las observaciones sin cambiar el estado
  ActividadTrackingState actualizarObservaciones(String? nuevasObservaciones) {
    return ActividadTrackingState(
      idActividad: idActividad,
      estado: estado,
      inicioActual: inicioActual,
      periodos: periodos,
      observaciones: nuevasObservaciones,
    );
  }

  /// Serialización para SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'idActividad': idActividad,
      'estado': estado.name,
      'inicioActual': inicioActual?.toIso8601String(),
      'periodos': periodos.map((p) => p.toJson()).toList(),
      'observaciones': observaciones,
    };
  }

  /// Deserialización desde SharedPreferences
  factory ActividadTrackingState.fromJson(Map<String, dynamic> json) {
    return ActividadTrackingState(
      idActividad: json['idActividad'] as int,
      estado: EstadoActividad.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoActividad.noIniciada,
      ),
      inicioActual: json['inicioActual'] != null
          ? DateTime.parse(json['inicioActual'] as String)
          : null,
      periodos: (json['periodos'] as List)
          .map((p) => PeriodoTrabajo.fromJson(p as Map<String, dynamic>))
          .toList(),
      observaciones: json['observaciones'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ActividadTrackingState.fromJsonString(String jsonString) {
    return ActividadTrackingState.fromJson(jsonDecode(jsonString));
  }
}

/// Estados posibles de una actividad
enum EstadoActividad {
  noIniciada,
  enProceso,
  pausada,
  finalizada,
}

/// Periodo de trabajo (inicio, pausa, reanudación, finalización)
class PeriodoTrabajo {
  final DateTime inicio;
  final DateTime? fin;
  final TipoEvento tipo;

  PeriodoTrabajo({
    required this.inicio,
    this.fin,
    required this.tipo,
  });

  /// Duración del periodo (null si no está cerrado)
  Duration? get duracion {
    if (fin == null) return null;
    return fin!.difference(inicio);
  }

  /// Cierra el periodo con una fecha de fin
  PeriodoTrabajo cerrar(DateTime fechaFin) {
    return PeriodoTrabajo(
      inicio: inicio,
      fin: fechaFin,
      tipo: tipo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inicio': inicio.toIso8601String(),
      'fin': fin?.toIso8601String(),
      'tipo': tipo.name,
    };
  }

  factory PeriodoTrabajo.fromJson(Map<String, dynamic> json) {
    return PeriodoTrabajo(
      inicio: DateTime.parse(json['inicio'] as String),
      fin: json['fin'] != null ? DateTime.parse(json['fin'] as String) : null,
      tipo: TipoEvento.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoEvento.inicio,
      ),
    );
  }
}

/// Tipos de eventos en el historial
enum TipoEvento {
  inicio,
  pausa,
  reanudacion,
  finalizacion,
}
