import LumiUI
import ProviderRootView
import SwiftUI

/// 根视图的布局配置。
///
/// 共享包提供一个**可配置**的默认根视图：顶部工具栏 + 内容区 + 可选的
/// 神秘背景。宿主通过本类型声明自己的根视图长什么样，无需再复制一份
/// 宿主专属的视图代码。
///
/// 默认值是「最简」形态：只有内容区，没有工具栏、没有背景 —— 与
/// `DefaultRootViewProviding` 的默认表现一致。需要工具栏与主题背景的
/// 宿主（JuiceNote / Kuzee 等）打开对应开关即可。
public struct RootViewLayoutConfiguration: Sendable, Equatable {
    /// 是否在根视图顶部渲染工具栏区域。
    ///
    /// 仅 macOS 生效（iOS 的工具栏由导航栏承载）。工具栏区域被显式隐藏
    /// 或未安装视图时不渲染。
    public let showsToolbar: Bool

    /// 是否在根视图背景铺一层主题渐变（`mystiqueBackground`）。
    public let usesMystiqueBackground: Bool

    /// 内容区没有贡献时的空态文案。
    public let emptyStateTitle: String

    public init(
        showsToolbar: Bool = false,
        usesMystiqueBackground: Bool = false,
        emptyStateTitle: String = RootContentComposer.defaultEmptyStateTitle
    ) {
        self.showsToolbar = showsToolbar
        self.usesMystiqueBackground = usesMystiqueBackground
        self.emptyStateTitle = emptyStateTitle
    }

    /// 开启顶部工具栏与主题背景的布局（JuiceNote / Kuzee 迁移前的形态）。
    public static let toolbarWithMystiqueBackground = Self(
        showsToolbar: true,
        usesMystiqueBackground: true
    )

    /// 只有内容区的最简布局（Wakey 迁移前的形态）。
    public static let minimal = Self()
}

/// 可配置的默认根视图 provider。
///
/// 在 `DefaultRootViewProviding` 的通用贡献 API 之上，按
/// `RootViewLayoutConfiguration` 组合出宿主专属的根布局。
///
/// - 顶部工具栏（可选，仅 macOS）；
/// - 内容区（底图 + overlay）；
/// - 主题渐变背景（可选）。
@MainActor
open class ConfigurableRootViewProviding: DefaultRootViewProviding {
    /// 根视图的布局配置。
    public let layout: RootViewLayoutConfiguration

    public init(layout: RootViewLayoutConfiguration = .minimal) {
        self.layout = layout
        super.init()
    }

    open override func makeRootView() -> AnyView {
        AnyView(ConfigurableRootHostView(provider: self, layout: layout))
    }
}

/// 可配置根视图的宿主视图。
///
/// 视图本身不持有任何判断逻辑：工具栏是否渲染、内容底图来自哪里，
/// 全部由 `RootContentComposer` 决定，因此这些决策可以脱离视图树直接单测。
@MainActor
private struct ConfigurableRootHostView: View {
    @ObservedObject var provider: ConfigurableRootViewProviding
    let layout: RootViewLayoutConfiguration

    var body: some View {
        VStack(spacing: 0) {
#if os(macOS)
            if layout.showsToolbar,
               RootContentComposer.shouldRenderToolbar(for: provider),
               let toolbarView = provider.toolbarView {
                toolbarView
                AppDivider(.horizontal)
            }
#endif

            rootContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(RootBackgroundModifier(usesMystiqueBackground: layout.usesMystiqueBackground))
#if os(macOS)
        .ignoresSafeArea()
#endif
    }

    private var rootContent: AnyView {
        RootContentComposer.makeRootContent(
            for: provider,
            emptyStateTitle: layout.emptyStateTitle
        )
    }
}

/// 按开关决定是否铺主题渐变背景。
///
/// 用 modifier 而不是 `background { if ... }`，是为了在关闭背景时**完全不**
/// 附加背景层 —— 与迁移前「没有 `.background` 修饰符」的渲染结果一致。
private struct RootBackgroundModifier: ViewModifier {
    let usesMystiqueBackground: Bool

    func body(content: Content) -> some View {
        if usesMystiqueBackground {
            content.background {
                Color.clear
                    .mystiqueBackground()
                    .ignoresSafeArea()
            }
        } else {
            content
        }
    }
}
