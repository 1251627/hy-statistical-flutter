import Flutter
import UIKit

/// Flutter plugin entry. Exposes a single method `collectAdFingerprint` that returns
/// a Map<String, String> with idfa / idfv / paid / os to the Dart side.
public class HyStatisticalFlutterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "hy_statistical_flutter/ad_fingerprint",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(HyStatisticalFlutterPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "collectAdFingerprint":
            let fp = HyAdFingerprint.collect()
            result([
                "os": fp.os,
                "idfa": fp.idfa,
                "idfv": fp.idfv,
                "paid": fp.paid,
            ])
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
