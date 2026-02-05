import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:hgtrack/features/time_tracking/data/models/pending_sync_activity.dart';
import 'package:hgtrack/features/time_tracking/data/services/pending_sync_service.dart';

/// Servicio singleton para monitorear el estado de conectividad.
/// Detecta cambios online/offline y ejecuta auto-sync al reconectar.
class ConnectivityService {
  // Singleton
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _initialized = false;
  bool _isSyncing = false;

  /// Stream controller para notificar cambios de estado de conexion
  final _onlineController = StreamController<bool>.broadcast();

  /// Stream controller para notificar resultados de auto-sync
  final _syncResultController = StreamController<SyncResult>.broadcast();

  /// Stream de estado de conexion (true = online, false = offline)
  Stream<bool> get onlineStream => _onlineController.stream;

  /// Stream de resultados de sincronizacion automatica
  Stream<SyncResult> get syncResultStream => _syncResultController.stream;

  /// Estado actual de conexion
  bool get isOnline => _isOnline;

  /// Si esta sincronizando actualmente
  bool get isSyncing => _isSyncing;

  /// Inicializa el servicio y comienza a escuchar cambios de conectividad
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Verificar estado inicial
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(results);
      _onlineController.add(_isOnline);
    } catch (e) {
      print('Error al verificar conectividad inicial: $e');
      _isOnline = true; // Asumir online si falla la verificacion
    }

    // Escuchar cambios
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = _hasConnection(results);

        _onlineController.add(_isOnline);

        // Transicion offline -> online: ejecutar auto-sync
        if (!wasOnline && _isOnline) {
          print('Conexion restaurada. Iniciando auto-sync...');
          _autoSync();
        }
      },
    );
  }

  /// Verifica si hay conexion real (no solo "none")
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
  }

  /// Verificacion puntual de conectividad
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(results);
      return _isOnline;
    } catch (e) {
      print('Error al verificar conectividad: $e');
      return _isOnline;
    }
  }

  /// Ejecuta sincronizacion automatica de actividades pendientes
  Future<void> _autoSync() async {
    if (_isSyncing) return; // Evitar sincronizaciones concurrentes

    _isSyncing = true;

    try {
      final syncService = PendingSyncService();
      final pendingCount = await syncService.getPendingCount();

      if (pendingCount == 0) {
        _isSyncing = false;
        return;
      }

      print('Auto-sync: $pendingCount actividades pendientes');
      final result = await syncService.syncAllPending();

      _syncResultController.add(result);

      if (result.todosExitosos) {
        print('Auto-sync completado: ${result.exitosos} exitosas');
      } else if (result.parcial) {
        print('Auto-sync parcial: ${result.exitosos}/${result.total} exitosas');
      } else {
        print('Auto-sync fallido: ${result.fallidos} errores');
      }
    } catch (e) {
      print('Error en auto-sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Fuerza una sincronizacion manual (llamada desde UI si es necesario)
  Future<SyncResult?> forceSync() async {
    if (_isSyncing) return null;

    _isSyncing = true;

    try {
      final syncService = PendingSyncService();
      final pendingCount = await syncService.getPendingCount();

      if (pendingCount == 0) {
        return SyncResult(total: 0, exitosos: 0, fallidos: 0, errores: []);
      }

      final result = await syncService.syncAllPending();
      _syncResultController.add(result);
      return result;
    } catch (e) {
      print('Error en sync manual: $e');
      return null;
    } finally {
      _isSyncing = false;
    }
  }

  /// Libera recursos
  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
    _syncResultController.close();
    _initialized = false;
  }
}
