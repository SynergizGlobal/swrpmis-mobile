import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/home_page.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

/// Maps FCM `data.type` (+ optional `referenceType` / `referenceId`) to a route.
abstract final class NotificationRouteResolver {
  static String resolve({
    required String? type,
    required RfiUserRole role,
    String? referenceType,
    String? referenceId,
  }) {
    switch ((type ?? '').trim().toUpperCase()) {
      case 'RFI_CREATED':
      case 'RFI_UPDATED':
      case 'RFI_CLOSED':
      case 'RFI_DELETED':
        return _section(RfiMenuId.log);
      case 'RFI_INSPECTION':
        return _section(RfiMenuId.inspection);
      case 'RFI_VALIDATION':
        return role.canViewValidation
            ? _section(RfiMenuId.validation)
            : _section(RfiMenuId.log);
      case 'QUALITY_INSPECTION':
        return _qualityPath(referenceId);
      case 'PROGRESS_VALIDATION_APPROVED':
        return '${_modulePath('validate-data')}?tab=approved';
      case 'PROGRESS_VALIDATION_REJECTED':
        return '${_modulePath('validate-data')}?tab=rejected';
      default:
        return _homeForReferenceType(referenceType);
    }
  }

  static String _section(RfiMenuId id) => '/rfi/section/${id.name}';

  static String _qualityPath(String? referenceId) {
    final String id = (referenceId ?? '').trim();
    final String path = _modulePath('quality');
    if (id.isEmpty) {
      return path;
    }
    return '$path?inspection_id=${Uri.encodeQueryComponent(id)}';
  }

  static String _modulePath(String id) {
    for (final AppModule module in ModuleCatalog.all) {
      if (module.id == id) {
        return module.routePath;
      }
    }
    return HomePage.routePath;
  }

  static String _homeForReferenceType(String? referenceType) {
    switch ((referenceType ?? '').trim().toUpperCase()) {
      case 'RFI':
        return ModuleCatalog.rfi.routePath;
      default:
        return HomePage.routePath;
    }
  }

  static String? typeFromData(Map<String, dynamic> data) {
    final dynamic raw = data['type'] ?? data['notificationType'];
    final String value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String? referenceTypeFromData(Map<String, dynamic> data) {
    final dynamic raw =
        data['referenceType'] ?? data['reference_type'] ?? data['refType'];
    final String value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String? referenceIdFromData(Map<String, dynamic> data) {
    final dynamic raw =
        data['referenceId'] ??
        data['reference_id'] ??
        data['rfiId'] ??
        data['rfi_id'] ??
        data['id'];
    final String value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String? userIdFromData(Map<String, dynamic> data) {
    final dynamic raw = data['userId'] ?? data['user_id'] ?? data['uid'];
    final String value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// When FCM includes [notificationUserId], it must match the session user.
  /// Missing FCM userId is allowed (older payloads).
  static bool isIntendedForUser({
    required String? notificationUserId,
    required String? sessionUserId,
  }) {
    final String target = (notificationUserId ?? '').trim();
    if (target.isEmpty) {
      return true;
    }
    final String current = (sessionUserId ?? '').trim();
    if (current.isEmpty) {
      return true;
    }
    return target.toUpperCase() == current.toUpperCase();
  }
}
