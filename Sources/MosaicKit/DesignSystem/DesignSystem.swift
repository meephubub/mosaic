import SwiftUI

/// Central design-system namespace. All visual constants live here so the app
/// stays visually consistent and re-theming stays a one-place change.
enum DS {
    // MARK: Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: Radii

    enum Radii {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 999
    }

    // MARK: Colors

    enum Colors {
        /// The near-black used for the mascot and primary surfaces.
        static let ink = Color.black
        /// Assistant bubble background on any scheme: a subtle elevated gray.
        static var assistantBubble: Color {
            Color(nsColor: .textBackgroundColor).opacity(0.001)
        }

        static func userBubble(scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.82)
        }

        static func userBubbleText(scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.primary : Color.white
        }
    }

    // MARK: Typography

    enum Typography {
        static let chatBody = Font.system(size: 14, weight: .regular)
        static let chatBodyMedium = Font.system(size: 14, weight: .medium)
        static let sectionHeader = Font.system(size: 13, weight: .semibold)
        static let pageTitle = Font.system(size: 28, weight: .bold)
        static let cardTitle = Font.system(size: 15, weight: .semibold)
        static let meta = Font.system(size: 12, weight: .regular)
    }

    // MARK: Animations

    enum Animations {
        /// The house spring used for most interactions.
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.78)
        /// A softer spring for large surfaces (notch → chat morph).
        static let softSpring = Animation.spring(response: 0.45, dampingFraction: 0.85)
        /// Gentle snappy animation for selection changes.
        static let smooth = Animation.smooth(duration: 0.25)
        /// Reduced-motion-safe variant: respects the system accessibility setting.
        static func adaptive(_ base: Animation = spring, reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : base
        }
    }
}
