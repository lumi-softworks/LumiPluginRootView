import Foundation

/// 工作台根布局的配置。
///
/// 工作台在「可选工具栏」之外再增加两个桌面区域：ActivityBar（入口竖栏）
/// 与 Rail（侧边内容栏）。宿主通过这些开关决定自己的根视图长什么样，
/// 而不需要复制一份宿主专属的布局代码。
public struct WorkbenchLayoutConfiguration: Sendable, Equatable {
    /// 是否在根视图顶部渲染工具栏区域。仅 macOS 生效。
    public let showsToolbar: Bool

    /// 没有任何活跃内容时是否显示欢迎占位。
    public let showsWelcomePlaceholder: Bool

    /// 是否用当前主题背景铺满根视图。
    public let usesThemeBackground: Bool

    /// 欢迎占位的标题。
    public let welcomeTitle: String

    /// 欢迎占位的说明文案。
    public let welcomeMessage: String

    public init(
        showsToolbar: Bool = true,
        showsWelcomePlaceholder: Bool = true,
        usesThemeBackground: Bool = true,
        welcomeTitle: String = Self.defaultWelcomeTitle,
        welcomeMessage: String = Self.defaultWelcomeMessage
    ) {
        self.showsToolbar = showsToolbar
        self.showsWelcomePlaceholder = showsWelcomePlaceholder
        self.usesThemeBackground = usesThemeBackground
        self.welcomeTitle = welcomeTitle
        self.welcomeMessage = welcomeMessage
    }

    /// 标准工作台：工具栏 + ActivityBar + Rail + 内容区。
    public static let standard = Self()

    /// 无工具栏的工作台：适合把工具栏交给宿主自绘的窗口。
    public static let withoutToolbar = Self(showsToolbar: false)

    /// 共享包自带的默认欢迎标题。
    public nonisolated static let defaultWelcomeTitle = String(
        localized: "Welcome",
        table: "WorkbenchRootView",
        bundle: .module
    )

    /// 共享包自带的默认欢迎说明。
    public nonisolated static let defaultWelcomeMessage = String(
        localized: "Select an item from the ActivityBar to get started",
        table: "WorkbenchRootView",
        bundle: .module
    )
}
