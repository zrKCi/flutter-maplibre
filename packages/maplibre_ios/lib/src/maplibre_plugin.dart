import 'package:flutter/services.dart';
import 'package:maplibre_ios/src/map_state.dart';
import 'package:maplibre_ios/src/offline_manager.dart';
import 'package:maplibre_ios/src/permission_manager.dart';
import 'package:maplibre_platform_interface/maplibre_platform_interface.dart';

/// iOS implementation of the federated MapLibre plugin.
final class MapLibrePlugin extends MapLibrePlatform {
  static const _requestHeadersChannel = MethodChannel(
    'plugins.flutter.io/maplibre/request_headers',
  );

  /// This static method registers [MapLibrePlugin] when running on iOS.
  static void registerWith() => MapLibrePlatform.instance = MapLibrePlugin();

  @override
  MapLibreMapState createWidgetState() => MapLibreMapStateIos();

  @override
  Future<OfflineManager> createOfflineManager() =>
      OfflineManagerIos.createInstance();

  @override
  PermissionManager createPermissionManager() => const PermissionManagerIos();

  @override
  Future<void> setRequestHeaders(String host, Map<String, String> headers) =>
      _requestHeadersChannel.invokeMethod<void>('setRequestHeaders', {
        'host': host,
        'headers': headers,
      });

  @override
  Future<void> clearRequestHeaders(String host) => _requestHeadersChannel
      .invokeMethod<void>('clearRequestHeaders', {'host': host});

  @override
  bool get offlineManagerIsSupported => true;

  @override
  bool get permissionManagerIsSupported => false;

  @override
  bool get userLocationIsSupported => true;
}
