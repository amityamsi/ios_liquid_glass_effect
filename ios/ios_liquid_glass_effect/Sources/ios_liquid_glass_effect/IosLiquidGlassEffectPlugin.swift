import Flutter
import UIKit

/// Requires the iOS 26 SDK to build; runtime fallbacks support iOS 13 and later.
public final class IosLiquidGlassEffectPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(
            name: "ios_liquid_glass_effect/control",
            binaryMessenger: messenger
        )
        registrar.addMethodCallDelegate(IosLiquidGlassEffectPlugin(), channel: channel)
        registrar.register(
            GlassViewFactory(messenger: messenger, kind: .surface),
            withId: "ios_liquid_glass_effect/surface"
        )
        registrar.register(
            GlassViewFactory(messenger: messenger, kind: .button),
            withId: "ios_liquid_glass_effect/button"
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "getCapabilities" else {
            result(FlutterMethodNotImplemented)
            return
        }
        let nativeGlassAvailable: Bool
        if #available(iOS 26.0, *) {
            nativeGlassAvailable = true
        } else {
            nativeGlassAvailable = false
        }
        result([
            "nativeGlassAvailable": nativeGlassAvailable,
            "systemVersion": UIDevice.current.systemVersion,
            "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled,
            "reduceMotion": UIAccessibility.isReduceMotionEnabled,
            "increaseContrast": UIAccessibility.isDarkerSystemColorsEnabled
        ])
    }
}

private enum GlassViewKind {
    case surface
    case button
}

private final class GlassViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let kind: GlassViewKind

    init(messenger: FlutterBinaryMessenger, kind: GlassViewKind) {
        self.messenger = messenger
        self.kind = kind
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        GlassPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            kind: kind,
            configuration: args as? [String: Any] ?? [:]
        )
    }
}

private protocol GlassContent: AnyObject {
    var rootView: UIView { get }
    func update(_ configuration: [String: Any])
}

private final class GlassPlatformView: NSObject, FlutterPlatformView {
    private let channel: FlutterMethodChannel
    private let content: GlassContent

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        kind: GlassViewKind,
        configuration: [String: Any]
    ) {
        channel = FlutterMethodChannel(
            name: "ios_liquid_glass_effect/view/\(viewId)",
            binaryMessenger: messenger
        )
        switch kind {
        case .surface:
            content = GlassSurfaceView(frame: frame)
        case .button:
            content = GlassButtonView(frame: frame)
        }
        super.init()
        content.update(configuration)

        if let button = content as? GlassButtonView {
            button.onTap = { [weak self] in
                self?.channel.invokeMethod("tap", arguments: nil)
            }
        }

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(FlutterError(
                    code: "disposed",
                    message: "The native glass view has been disposed.",
                    details: nil
                ))
                return
            }
            guard call.method == "update" else {
                result(FlutterMethodNotImplemented)
                return
            }
            guard let configuration = call.arguments as? [String: Any] else {
                result(FlutterError(
                    code: "invalid_arguments",
                    message: "update requires a complete configuration map.",
                    details: nil
                ))
                return
            }
            self.content.update(configuration)
            result(nil)
        }
    }

    func view() -> UIView { content.rootView }

    deinit {
        channel.setMethodCallHandler(nil)
    }
}

/// Passive native material; Flutter owns foreground content and its gestures.
private final class GlassSurfaceView: UIView, GlassContent {
    private let effectView = UIVisualEffectView(effect: nil)
    private let legacyFill = UIView()
    private var configuration: [String: Any] = [:]
    private var transparencyObserver: NSObjectProtocol?
    private var cornerRadius: Double = 24

    var rootView: UIView { self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        // Keep the host unclipped: a parent mask can break backdrop effects.
        clipsToBounds = false
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        effectView.isUserInteractionEnabled = false
        effectView.isOpaque = false
        addSubview(effectView)
        legacyFill.isUserInteractionEnabled = false
        legacyFill.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.contentView.addSubview(legacyFill)

        if #available(iOS 26.0, *) {
            // UIKit adapts native Liquid Glass to accessibility settings.
        } else {
            transparencyObserver = NotificationCenter.default.addObserver(
                forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.update(self.configuration)
            }
        }
    }

    required init?(coder: NSCoder) { return nil }

    func update(_ configuration: [String: Any]) {
        self.configuration = configuration
        overrideUserInterfaceStyle = userInterfaceStyle(configuration)
        cornerRadius = finiteDouble(configuration["cornerRadius"], fallback: 24, minimum: 0)
        let tint = argbColor(configuration["tintColor"])

        if #available(iOS 26.0, *) {
            let style: UIGlassEffect.Style =
                configuration["style"] as? String == "clear" ? .clear : .regular
            let effect = UIGlassEffect(style: style)
            effect.tintColor = tint
            effect.isInteractive = false
            effectView.effect = effect
            effectView.cornerConfiguration = .corners(radius: .fixed(cornerRadius))
            legacyFill.isHidden = true
        } else {
            let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
            effectView.effect = reduceTransparency ? nil : UIBlurEffect(style: .systemMaterial)
            // Clipping the effect itself is supported; the parent stays unclipped.
            effectView.layer.cornerCurve = .continuous
            effectView.layer.cornerRadius = CGFloat(cornerRadius)
            effectView.clipsToBounds = true
            legacyFill.isHidden = false
            if reduceTransparency {
                legacyFill.backgroundColor = .secondarySystemBackground
            } else {
                legacyFill.backgroundColor = tint?.withAlphaComponent(
                    (tint?.cgColor.alpha ?? 0) * 0.16
                ) ?? .clear
            }
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        effectView.frame = bounds
        legacyFill.frame = effectView.contentView.bounds
    }

    deinit {
        if let transparencyObserver {
            NotificationCenter.default.removeObserver(transparencyObserver)
        }
    }
}

/// A complete UIKit button so UIKit owns its highlight, touch, and semantics.
private final class GlassButtonView: UIView, GlassContent {
    private let button = UIButton(type: .system)
    private let legacyBackdrop = UIVisualEffectView(effect: nil)
    private let legacyFill = UIView()
    private var configuration: [String: Any] = [:]
    private var transparencyObserver: NSObjectProtocol?
    var onTap: (() -> Void)?

    var rootView: UIView { self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        clipsToBounds = false
        isAccessibilityElement = false

        legacyBackdrop.isUserInteractionEnabled = false
        legacyBackdrop.isOpaque = false
        legacyBackdrop.clipsToBounds = true
        legacyBackdrop.layer.cornerCurve = .continuous
        addSubview(legacyBackdrop)
        legacyFill.isUserInteractionEnabled = false
        legacyFill.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        legacyBackdrop.contentView.addSubview(legacyFill)
        addSubview(button)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = false

        if #available(iOS 26.0, *) {
            legacyBackdrop.isHidden = true
        } else {
            transparencyObserver = NotificationCenter.default.addObserver(
                forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.update(self.configuration)
            }
        }
    }

    required init?(coder: NSCoder) { return nil }

    func update(_ configuration: [String: Any]) {
        self.configuration = configuration
        overrideUserInterfaceStyle = userInterfaceStyle(configuration)
        let label = configuration["label"] as? String ?? ""
        let direction: UISemanticContentAttribute
        switch configuration["layoutDirection"] as? String {
        case "rtl": direction = .forceRightToLeft
        case "ltr": direction = .forceLeftToRight
        default: direction = .unspecified
        }
        semanticContentAttribute = direction
        button.semanticContentAttribute = direction
        let imageName = configuration["systemImage"] as? String
        let prominent = configuration["prominent"] as? Bool ?? false
        let tint = argbColor(configuration["tintColor"])
        let fontSize = CGFloat(finiteDouble(configuration["fontSize"], fallback: 17, minimum: 1))
        let image = imageName.flatMap { UIImage(systemName: $0) }?.applyingSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: fontSize, weight: .semibold)
        )
        button.isEnabled = configuration["enabled"] as? Bool ?? true
        button.accessibilityLabel = configuration["accessibilityLabel"] as? String ?? label
        // nil restores the UIKit/inherited tint instead of inventing a default.
        button.tintColor = tint

        if #available(iOS 26.0, *) {
            var buttonConfiguration: UIButton.Configuration =
                prominent ? .prominentGlass() : .glass()
            buttonConfiguration.title = label
            buttonConfiguration.image = image
            buttonConfiguration.imagePadding = 8
            buttonConfiguration.cornerStyle = .capsule
            buttonConfiguration.buttonSize = .large
            if let tint {
                buttonConfiguration.baseBackgroundColor = tint
            }
            buttonConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
                incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
                return outgoing
            }
            button.configuration = buttonConfiguration
            legacyBackdrop.isHidden = true
        } else {
            updateLegacyBackground(prominent: prominent, tint: tint)
            let foreground: UIColor = prominent ? .white : (tint ?? .label)
            if #available(iOS 15.0, *) {
                var buttonConfiguration = UIButton.Configuration.plain()
                buttonConfiguration.title = label
                buttonConfiguration.image = image
                buttonConfiguration.imagePadding = 8
                buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(
                    top: 10, leading: 16, bottom: 10, trailing: 16
                )
                buttonConfiguration.baseForegroundColor = foreground
                buttonConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
                    incoming in
                    var outgoing = incoming
                    outgoing.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
                    return outgoing
                }
                button.configuration = buttonConfiguration
            } else {
                button.setTitle(label, for: .normal)
                button.setImage(image, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
                button.setTitleColor(foreground, for: .normal)
                button.setTitleColor(foreground.withAlphaComponent(0.45), for: .disabled)
                button.tintColor = foreground
                button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
            }
        }
        setNeedsLayout()
    }

    private func updateLegacyBackground(prominent: Bool, tint: UIColor?) {
        legacyBackdrop.isHidden = false
        if prominent {
            legacyBackdrop.effect = nil
            legacyFill.backgroundColor = (tint ?? .systemBlue).withAlphaComponent(1)
        } else if UIAccessibility.isReduceTransparencyEnabled {
            legacyBackdrop.effect = nil
            legacyFill.backgroundColor = .secondarySystemBackground
        } else {
            legacyBackdrop.effect = UIBlurEffect(style: .systemMaterial)
            legacyFill.backgroundColor = .clear
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
        legacyBackdrop.frame = bounds
        legacyBackdrop.layer.cornerRadius = min(bounds.width, bounds.height) / 2
        legacyFill.frame = legacyBackdrop.contentView.bounds
    }

    @objc private func didTap() {
        guard button.isEnabled else { return }
        onTap?()
    }

    deinit {
        if let transparencyObserver {
            NotificationCenter.default.removeObserver(transparencyObserver)
        }
    }
}

private func userInterfaceStyle(_ configuration: [String: Any]) -> UIUserInterfaceStyle {
    switch configuration["brightness"] as? String {
    case "light": return .light
    case "dark": return .dark
    default: return .unspecified
    }
}

private func finiteDouble(_ value: Any?, fallback: Double, minimum: Double) -> Double {
    guard let number = value as? NSNumber, number.doubleValue.isFinite else { return fallback }
    return max(minimum, number.doubleValue)
}

private func argbColor(_ value: Any?) -> UIColor? {
    guard let number = value as? NSNumber else { return nil }
    let color = UInt32(truncatingIfNeeded: number.uint64Value)
    return UIColor(
        red: CGFloat((color >> 16) & 0xff) / 255,
        green: CGFloat((color >> 8) & 0xff) / 255,
        blue: CGFloat(color & 0xff) / 255,
        alpha: CGFloat((color >> 24) & 0xff) / 255
    )
}
