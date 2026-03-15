import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AdOverlayRecoveryService {
  AdOverlayRecoveryService._();

  static const MethodChannel _channel = MethodChannel(
    'com.eirenya.quiznetic/ads_recovery',
  );

  static Future<bool> finishStuckAdActivity({required String reason}) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'finishStuckAdActivity',
        {'reason': reason},
      );
      final activityClass = response?['activityClass'] as String?;
      final finished = response?['finished'] == true;
      debugPrint(
        'Rewarded ad recovery '
        'reason=$reason '
        'finished=$finished '
        'activity=${activityClass ?? 'none'}',
      );
      return finished;
    } on MissingPluginException {
      debugPrint(
        'Rewarded ad recovery reason=$reason '
        'finished=false activity=missing_plugin',
      );
      return false;
    } on PlatformException catch (error) {
      debugPrint(
        'Rewarded ad recovery '
        'reason=$reason '
        'finished=false '
        'platform_error=${error.code}:${error.message}',
      );
      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Rewarded ad recovery '
        'reason=$reason '
        'finished=false '
        'error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
