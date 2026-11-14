import LumiUI
import ProviderRootView
import SwiftUI

/// 工作台根视图：按平台选择桌面三栏或移动端底部标签栏。
@MainActor
struct WorkbenchRootHostView: View {
    @ObservedObject var provider: WorkbenchRootViewProviding

    var body: some View {
        #if os(macOS)
        DesktopWorkbenchRootHostView(provider: provider)
        #else
        MobileWorkbenchRootHostView(provider: provider)
        #endif
    }
}

#if os(macOS)
/// 桌面工作台：顶部工具栏 +（ActivityBar 竖栏 | Rail | 内容区）。
@MainActor
private struct DesktopWorkbenchRootHostView: View {
    @ObservedObject var provider: WorkbenchRootViewProviding
    @LumiTheme private var theme
    @State private var observationRevision = 0
    @State private var observerHandle: (any RootViewObserverHandle)?

    var body: some View {
        VStack(spacing: 0) {
            if provider.layout.showsToolbar, let toolbarView = provider.toolbarView {
                toolbarView
                AppDivider()
            }

            HStack(spacing: 0) {
                if let activityBarView = provider.activityBarView {
                    activityBarView
                }

                WorkbenchSplitView(provider: provider, layout: provider.layout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("root.main")
        .modifier(WorkbenchBackgroundModifier(usesThemeBackground: provider.layout.usesThemeBackground))
        .appThemedAppearance()
        .background {
            ThemeWindowAppearanceBridge()
        }
        .environmentObject(AppThemeVM.shared)
        .ignoresSafeArea()
        .id(observationRevision)
        .onAppear {
            guard observerHandle == nil else { return }
            observerHandle = provider.addRootViewObserver { event in
                switch event {
                case .toolbarViewChanged, .activityBarViewChanged:
                    observationRevision += 1
                default:
                    break
                }
            }
        }
        .onDisappear {
            observerHandle?.cancel()
            observerHandle = nil
        }
    }
}
#endif

/// 按开关决定是否铺主题背景。
///
/// 用 modifier 而不是 `background { if ... }`，是为了在关闭背景时完全不附加
/// 背景层，保持与关闭前的渲染结果一致。
@MainActor
struct WorkbenchBackgroundModifier: ViewModifier {
    let usesThemeBackground: Bool
    @LumiTheme private var theme

    func body(content: Content) -> some View {
        if usesThemeBackground {
            content.background(theme.background)
        } else {
            content
        }
    }
}
