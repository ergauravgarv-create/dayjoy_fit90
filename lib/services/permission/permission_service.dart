import '../../data/models/health_enums.dart';

/// Runtime permission handling behind a single interface so UI never touches
/// `permission_handler` directly. Implemented by [MockPermissionService]
/// (default) and `RuntimePermissionService` (real, guarded).
abstract interface class PermissionService {
  Future<PermissionStatus> status(AppPermission permission);
  Future<PermissionStatus> request(AppPermission permission);

  /// Opens the OS app-settings page (used when a permission is permanently
  /// denied and can only be re-granted from Settings).
  Future<void> openAppSettings();
}

/// Runnable default. Starts "notDetermined", grants on request. Flip
/// [autoGrant] to false to exercise the denied / permanently-denied UI.
class MockPermissionService implements PermissionService {
  MockPermissionService({this.autoGrant = true});

  final bool autoGrant;
  final Map<AppPermission, PermissionStatus> _state = {};

  @override
  Future<PermissionStatus> status(AppPermission permission) async =>
      _state[permission] ?? PermissionStatus.notDetermined;

  @override
  Future<PermissionStatus> request(AppPermission permission) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final PermissionStatus result =
        autoGrant ? PermissionStatus.granted : PermissionStatus.denied;
    _state[permission] = result;
    return result;
  }

  @override
  Future<void> openAppSettings() async {}
}
