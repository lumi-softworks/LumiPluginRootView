import LumiUI
import ProviderRootView
import SwiftUI

// MARK: - 决策模型

/// 根内容底图的来源。
///
/// 原本这段判断内联在视图 `body` 里，只能靠肉眼或渲染快照验证。现在把它
/// 建模成纯值类型，组装顺序与优先级就能被直接断言，而视图只负责按结果渲染。
public enum RootContentSource: Equatable {
    /// 内容区被隐藏：渲染 `EmptyView`，即使已注册内容贡献。
    case hidden
    /// 已注册内容贡献：使用该贡献视图。
    case contentView
    /// 没有内容贡献：渲染空态占位。
    case emptyState
}

// MARK: - 组装器

/// 根视图的内容组装策略。
///
/// 视图不再持有任何判断逻辑，只调用这里的方法并渲染返回值；因此这些决策
/// 可以在不构建 SwiftUI 视图树的前提下直接单测。
@MainActor
public enum RootContentComposer {

    // MARK: - 工具栏

    /// 根视图是否应该渲染顶部工具栏。
    ///
    /// 工具栏区域被显式隐藏时不渲染；未设置工具栏视图时也不渲染。
    public static func shouldRenderToolbar(for provider: any RootViewProviding) -> Bool {
        toolbarSource(for: provider) != nil
    }

    /// 工具栏的来源，`nil` 表示不渲染工具栏。
    public static func toolbarSource(for provider: any RootViewProviding) -> AnyView? {
        guard !provider.isRegionHidden(.toolbar) else { return nil }
        return provider.view(for: .toolbar)
    }

    // MARK: - 内容区

    /// 判定内容区底图来源。
    ///
    /// 判定顺序有意为之：
    /// 1. `isContentViewHidden` 或 `.content` 区域被隐藏 → `.hidden`；
    /// 2. 已注册内容贡献 → `.contentView`；
    /// 3. 其余情况 → `.emptyState`。
    public static func contentSource(for provider: any RootViewProviding) -> RootContentSource {
        if isContentHidden(for: provider) {
            return .hidden
        }
        if provider.view(for: .content) != nil {
            return .contentView
        }
        return .emptyState
    }

    /// 内容区是否被隐藏（任一隐藏开关生效即隐藏）。
    public static func isContentHidden(for provider: any RootViewProviding) -> Bool {
        provider.isContentViewHidden || provider.isRegionHidden(.content)
    }

    /// 按 `contentSource` 渲染出对应的底图视图。
    public static func makeBaseContent(
        for provider: any RootViewProviding,
        emptyStateTitle: String = RootContentComposer.defaultEmptyStateTitle
    ) -> AnyView {
        switch contentSource(for: provider) {
        case .hidden:
            return AnyView(EmptyView())
        case .contentView:
            return provider.view(for: .content) ?? AnyView(EmptyView())
        case .emptyState:
            return AnyView(
                AppEmptyState(
                    icon: "sparkles",
                    title: emptyStateTitle
                )
            )
        }
    }

    /// 组装最终根内容：底图 + 按顺序套用 overlay。
    public static func makeRootContent(
        for provider: any RootViewProviding,
        emptyStateTitle: String = RootContentComposer.defaultEmptyStateTitle
    ) -> AnyView {
        let baseContent = makeBaseContent(for: provider, emptyStateTitle: emptyStateTitle)
        return provider.overlays.reduce(baseContent) { content, overlay in
            overlay.wrap(content)
        }
    }

    /// 默认空态文案。
    ///
    /// 共享包自带这份文案的英 / 简中 / 繁中本地化；宿主若要改用自己的文案，
    /// 通过 `emptyStateTitle` 参数覆盖即可。
    ///
    /// 声明为 `nonisolated`：它是一份与 actor 无关的常量，宿主在装配期
    /// （可能还没进主 actor）构造布局配置时也要能引用。
    public nonisolated static let defaultEmptyStateTitle = String(
        localized: "当前没有可显示的内容",
        table: "WorkbenchRootView",
        bundle: .module
    )
}
