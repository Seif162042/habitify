import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive permission handling service
/// 
/// PERMISSION SYSTEM UNDERSTANDING:
/// 1. Runtime vs Install-time permissions
/// 2. Permission rationale (explain why needed)
/// 3. Graceful degradation (work without permission)
/// 4. Settings redirect (if permanently denied)
class PermissionService {
  
  /// Request all initial permissions with rationale
  static Future<void> requestInitialPermissions() async {
    // Request notification permission (Android 13+)
    await requestNotificationPermission();
    
    // Request activity recognition for step counter
    await requestActivityRecognitionPermission();
  }
  
  /// Request notification permission with rationale
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      // First time asking - request directly
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // User denied permanently - can't request again
      print('⚠️ Notification permission permanently denied');
      return false;
    }
    
    return false;
  }
  
  /// Request activity recognition with rationale dialog
  static Future<bool> requestActivityRecognitionPermission() async {
    final status = await Permission.activityRecognition.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.activityRecognition.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      print('⚠️ Activity recognition permission permanently denied');
      return false;
    }
    
    return false;
  }
  
  /// Show rationale dialog explaining why permission is needed
  static Future<bool> showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
    required Permission permission,
  }) async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            _buildPermissionBenefits(permission),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    
    if (shouldRequest == true) {
      final status = await permission.request();
      return status.isGranted;
    }
    
    return false;
  }
  
  /// Build benefits list for each permission type
  static Widget _buildPermissionBenefits(Permission permission) {
    List<String> benefits = [];
    
    if (permission == Permission.activityRecognition) {
      benefits = [
        '📊 Track your daily steps automatically',
        '🎯 Set and achieve step goals',
        '📈 View your activity history',
      ];
    } else if (permission == Permission.notification) {
      benefits = [
        '⏰ Get daily habit reminders',
        '🎉 Celebrate streak milestones',
        '🌙 Evening check-in notifications',
      ];
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: benefits.map((benefit) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(benefit, style: const TextStyle(fontSize: 14)),
      )).toList(),
    );
  }
  
  /// Check if permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }
  
  /// Handle permission denial - show options
  static Future<void> handlePermissionDenial(
    BuildContext context, {
    required String permissionName,
    required Permission permission,
  }) async {
    final status = await permission.status;
    
    if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      _showOpenSettingsDialog(context, permissionName);
    } else {
      // Show snackbar explaining the limitation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$permissionName permission denied. Some features may not work.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () async {
              await permission.request();
            },
          ),
        ),
      );
    }
  }
  
  /// Show dialog to open app settings
  static Future<void> _showOpenSettingsDialog(
    BuildContext context,
    String permissionName,
  ) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$permissionName permission was denied. To use this feature, please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    
    if (shouldOpen == true) {
      await openAppSettings();
    }
  }
  
  /// Get permission status summary for debugging
  static Future<Map<String, String>> getPermissionStatusSummary() async {
    return {
      'Notifications': (await Permission.notification.status).toString(),
      'Activity Recognition': (await Permission.activityRecognition.status).toString(),
    };
  }
}
