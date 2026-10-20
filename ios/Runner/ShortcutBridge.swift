import Flutter
import UIKit

@objc class ShortcutBridge: NSObject {
    static let shared = ShortcutBridge()
    private var channel: FlutterMethodChannel?
    private var pendingDeepLinkUrl: URL?

    private override init() {
        super.init()
    }

    func setup(with registrar: FlutterPluginRegistry) {
        // Can be initialized with registrar
    }

    func setup(with messenger: FlutterBinaryMessenger) {
        let methodChannel = FlutterMethodChannel(
            name: "com.voryn.erp/shortcut_bridge",
            binaryMessenger: messenger
        )
        self.channel = methodChannel

        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call: call, result: result)
        }

        // Deliver pending link if cold launched before channel setup
        if let pendingUrl = pendingDeepLinkUrl {
            deliverDeepLink(url: pendingUrl)
            pendingDeepLinkUrl = nil
        }
    }

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "openSettings":
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                result(false)
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:]) { success in
                    result(success)
                }
            } else {
                result(false)
            }

        case "openShortcutsApp":
            let urlString = (call.arguments as? [String: Any])?["url"] as? String ?? "shortcuts://"
            guard let url = URL(string: urlString) else {
                result(false)
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    result(success)
                }
            } else {
                result(false)
            }

        case "getDeviceModel":
            let device = UIDevice.current
            let info: [String: String] = [
                "model": device.model,
                "systemName": device.systemName,
                "systemVersion": device.systemVersion,
                "name": device.name
            ]
            result(info)

        case "getPendingDeepLink":
            if let pending = pendingDeepLinkUrl {
                result(pending.absoluteString)
                pendingDeepLinkUrl = nil
            } else {
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "voryn" else {
            return false
        }

        if channel != nil {
            deliverDeepLink(url: url)
        } else {
            pendingDeepLinkUrl = url
        }
        return true
    }

    private func deliverDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }

        var params: [String: Any] = [
            "rawUrl": url.absoluteString,
            "host": components.host ?? ""
        ]

        if let queryItems = components.queryItems {
            for item in queryItems {
                if let val = item.value {
                    if let doubleVal = Double(val) {
                        params[item.name] = doubleVal
                    } else {
                        params[item.name] = val
                    }
                }
            }
        }

        channel?.invokeMethod("onQuickAddTriggered", arguments: params)
    }
}
