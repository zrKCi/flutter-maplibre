import 'package:flutter/services.dart';
import 'package:maplibre_android/src/map_state.dart';
import 'package:maplibre_android/src/offline_manager.dart';
import 'package:maplibre_android/src/permission_manager.dart';
import 'package:maplibre_platform_interface/maplibre_platform_interface.dart';

/// Android implementation of the federated MapLibre plugin.
final class MapLibrePlugin extends MapLibrePlatform {
  static const _requestHeadersChannel = MethodChannel(
    'plugins.flutter.io/maplibre/request_headers',
  );

  /// This static method registers [MapLibrePlugin] when running on Android.
  static void registerWith() => MapLibrePlatform.instance = MapLibrePlugin();

  @override
  MapLibreMapState createWidgetState() => MapLibreMapStateAndroid();

  @override
  Future<OfflineManager> createOfflineManager() =>
      OfflineManagerAndroid.createInstance();

  @override
  PermissionManager createPermissionManager() => PermissionManagerAndroid();

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
  bool get permissionManagerIsSupported => true;

  @override
  bool get userLocationIsSupported => true;
}
