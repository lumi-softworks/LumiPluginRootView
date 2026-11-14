import LumiUI
import SwiftUI

/// 没有任何活跃内容时的欢迎占位。
@MainActor
struct WorkbenchWelcomeView: View {
    let layout: WorkbenchLayoutConfiguration
    @LumiTheme private var theme

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()

                Image(systemName: "rectangle.center.inset.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.primary)
                    .scaledToFit()
                    .frame(maxHeight: 80)

                VStack(spacing: DesignTokens.Spacing.md) {
                    Text(layout.welcomeTitle)
                        .font(.appTitle)
                        .foregroundStyle(theme.textPrimary)
                        .accessibilityIdentifier("root.welcome.title")

                    Text(layout.welcomeMessage)
                        .font(.appBody)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("root.welcome.description")
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backgroundView: some View {
        GeometryReader { geometry in
            let maxRadius = max(geometry.size.width, geometry.size.height)

            RadialGradient(
                gradient: Gradient(colors: [
                    theme.primary.opacity(0.06),
                    theme.primary.opacity(0.02),
                    theme.background.opacity(0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: maxRadius * 0.8
            )
            .ignoresSafeArea()
        }
    }
}
