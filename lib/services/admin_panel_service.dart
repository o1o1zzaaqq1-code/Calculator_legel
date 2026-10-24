import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AdminPanelService {
  static const String supabaseUrl = 'https://ezfqdgclpxemdvfoepru.supabase.co';
  static const String anonKey =
      'sb_publishable__7h1y1nGR9p027pJdGq8ZQ_Nc_EFPX4';
  static const String packageName = 'com.dimension.calculator';

  // 1. Fetch Remote Config (Ads, Buttons, Update Policy)
  static Future<Map<String, dynamic>?> fetchAppConfig() async {
    try {
      final uri = Uri.https(
        'ezfqdgclpxemdvfoepru.supabase.co',
        '/rest/v1/apps',
        {
          'package_name': 'eq.$packageName',
          'select': '*,app_ads(*),app_buttons(*)',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          debugPrint('[AdminPanelService] Remote config loaded successfully');
          return data[0] as Map<String, dynamic>;
        }
      } else {
        debugPrint(
            '[AdminPanelService] Remote config status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[AdminPanelService] Error loading remote config: $e');
    }
    return null;
  }

  // 2. Send Anonymous Device Telemetry & Check Ban / Test Mode
  static Future<Map<String, dynamic>?> syncDeviceHeartbeat(String appId) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceId = 'unknown';
      String model = 'Android Phone';
      String mfg = 'Unknown';
      String os = Platform.operatingSystemVersion;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Hardware Android ID
        model = androidInfo.model;
        mfg = androidInfo.manufacturer;
        os = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios_unknown';
        model = iosInfo.utsname.machine;
        mfg = 'Apple';
        os = 'iOS ${iosInfo.systemVersion}';
      }

      final url = Uri.parse('$supabaseUrl/rest/v1/app_devices');
      final response = await http.post(
        url,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates,return=representation',
        },
        body: jsonEncode({
          'app_id': appId,
          'device_id': deviceId,
          'device_model': model,
          'manufacturer': mfg,
          'os_version': os,
          'app_version': packageInfo.version,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          debugPrint('[AdminPanelService] Device heartbeat synced successfully');
          return data[0] as Map<String, dynamic>;
        }
      } else {
        debugPrint(
            '[AdminPanelService] Device heartbeat error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[AdminPanelService] Error sending telemetry: $e');
    }
    return null;
  }
}
