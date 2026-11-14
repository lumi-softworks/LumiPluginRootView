import Combine
import OSLog
import ProviderActivityBar
import ProviderRailView
import ProviderRootView
import SwiftUI

/// 工作台根视图 provider。
///
/// 在 `DefaultRootViewProviding` 的通用区域之上补齐桌面工作台需要的联动：
/// - Rail 可见性跟随 `RailViewProviding.hasVisibleTabs`；
/// - Rail 宽度从 provider 恢复、用户拖拽后回写；
/// - `hasRailContent` 区分「宿主允许显示 Rail」与「Rail 真的有没有内容」，
///   供根视图在内容从无到有时重建 split（空的 `HSplitView` 面板会被永久折叠）；
/// - ActivityBar 以 provider 形式注入，macOS 用其竖栏视图，iOS 用其 items 渲染底栏。
///
/// 聊天窗格、终端面板等宿主专属内容不在这里：它们通过 `trailingPane` /
/// `contentFooter` 等通用区域贡献，由宿主自己的插件装配。
@MainActor
open class WorkbenchRootViewProviding: DefaultRootViewProviding {
    /// 工作台布局配置。
    public let layout: WorkbenchLayoutConfiguration

    /// ActivityBar 的数据源。
    ///
    /// 根视图既要它的视图（macOS 竖栏），也要它的 items 与激活态（iOS 底栏）。
    @Published public private(set) var activityBarProvider: (any ActivityBarProviding)?

    /// Rail 当前是否有可渲染内容（可见标签或区块）。
    ///
    /// `isRailViewVisible` 只表达「宿主是否允许显示 Rail」，不表达「Rail 里有没有东西」。
    /// 首帧渲染出没有任何标签的空 Rail 面板时，`HSplitView` 会把这一侧折叠成 0 宽，
    /// 之后标签注册成功也不会自动展开。根视图用本属性作为 split 的 identity，
    /// 内容从无到有时整块重建。
    @Published public private(set) var hasRailContent = true

    private let logger: Logger
    private var railVisibilityObserver: (any RailViewProvidingObserverHandle)?
    private var railWidthObserver: (any RailViewProvidingObserverHandle)?
    private var railWidthResizeHandler: (@MainActor (CGFloat) -> Void)?
    private var lastRailViewVisibility = true
    private weak var boundRailProvider: (any RailViewProviding)?

    public init(
        layout: WorkbenchLayoutConfiguration = .standard,
        loggerSubsystem: String = "com.coffic.workbench.root-view"
    ) {
        self.layout = layout
        self.logger = Logger(subsystem: loggerSubsystem, category: "WorkbenchRootView")
        super.init()
    }

    // MARK: - ActivityBar

    /// 注入 ActivityBar provider。
    ///
    /// macOS 同时把 provider 的竖栏视图挂到 `.activityBar` 区域；
    /// iOS 不使用该竖栏视图，由根视图读取 `items` 自行渲染底部标签栏。
    open func setActivityBarProvider(_ provider: (any ActivityBarProviding)?) {
        activityBarProvider = provider
        #if os(macOS)
        setActivityBarView(provider?.makeActivityBarView())
        #endif
    }

    // MARK: - Rail

    open override func setRailView(_ view: AnyView?) {
        guard !isSameView(railView, view) else { return }
        if view == nil {
            // `setRailView(nil)` 可能只是宿主层的临时替换：保留最后一次可见性，
            // 以便恢复 Rail 视图时不会在标签仍可见的情况下露出空白区域。
            if isRailViewVisible {
                isRailViewVisible = false
            }
        } else if railView == nil {
            setRailViewVisible(lastRailViewVisibility)
        }
        super.setRailView(view)
    }

    open override func setRailViewVisible(_ visible: Bool) {
        guard isRailViewVisible != visible else { return }
        isRailViewVisible = visible
        lastRailViewVisibility = visible
        emitRootViewEvent(.railViewVisibilityChanged(visible))
    }

    open override func bindRailViewVisibility(to provider: any RailViewProviding) {
        railVisibilityObserver?.cancel()
        boundRailProvider = provider
        refreshHasRailContent()
        setRailViewVisible(provider.hasVisibleTabs)
        railVisibilityObserver = provider.addObserver { [weak self] event in
            switch event {
            case let .visibilityChanged(visible):
                self?.setRailViewVisible(visible)
                self?.refreshHasRailContent()
            case .tabsChanged, .visibleCategoriesChanged, .visibleTabIDChanged, .didAppear:
                self?.refreshHasRailContent()
            case .activeTabChanged, .widthChanged, .bottomItemsChanged:
                break
            }
        }
    }

    open override func bindRailViewWidth(
        to provider: any RailViewProviding,
        onResize: @escaping @MainActor (CGFloat) -> Void
    ) {
        railWidthObserver?.cancel()
        railWidthResizeHandler = onResize
        railWidth = provider.railWidth
        railWidthObserver = provider.addObserver { [weak self] event in
            guard case let .widthChanged(width) = event else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.railWidth = width
                self.emitRootViewEvent(.railWidthChanged(width))
            }
        }
    }

    open override func saveRailViewWidth(_ width: CGFloat) {
        railWidthResizeHandler?(width)
    }

    /// 依据已绑定的 Rail provider 重算 `hasRailContent`。
    ///
    /// 只在值确实改变时赋值，避免无意义的 `objectWillChange` 与视图重建。
    private func refreshHasRailContent() {
        let hasContent = boundRailProvider.map { $0.hasVisibleTabs || $0.hasVisibleSections } ?? false
        guard hasRailContent != hasContent else { return }
        hasRailContent = hasContent
    }

    // MARK: - 内容

    /// 是否存在可渲染的活跃内容。
    public var hasActiveContent: Bool {
        contentHeaderView != nil
            || contentView != nil
            || (contentFooterView != nil && !isContentFooterViewHidden)
            || trailingPane?.isVisible == true
    }

    // MARK: - 根视图

    open override func makeRootView() -> AnyView {
        AnyView(WorkbenchOverlayHostView(provider: self))
    }

    // MARK: - 注入守卫

    // `DefaultRootViewProviding` 的区域注入会无条件发布事件；装配流程可能重复
    // 注入同一状态（宿主重建视图树时），这里只在有值/无值状态变化时转发，
    // 避免无意义刷新与视图重建循环。

    open override func setToolbarView(_ view: AnyView?) {
        guard !isSameView(toolbarView, view) else { return }
        super.setToolbarView(view)
    }

    open override func setActivityBarView(_ view: AnyView?) {
        guard !isSameView(activityBarView, view) else { return }
        super.setActivityBarView(view)
    }

    open override func setContentHeaderView(_ view: AnyView?) {
        guard !isSameView(contentHeaderView, view) else { return }
        super.setContentHeaderView(view)
    }

    open override func setContentView(_ view: AnyView?) {
        guard !isSameView(contentView, view) else { return }
        super.setContentView(view)
    }

    open override func setContentFooterView(_ view: AnyView?) {
        guard !isSameView(contentFooterView, view) else { return }
        super.setContentFooterView(view)
    }

    open override func setTrailingPane(_ pane: RootViewPane?) {
        guard pane !== trailingPane else { return }
        trailingPane = pane
        emitRootViewEvent(.trailingPaneChanged)
    }

    /// 判断两次注入的视图是否「相同」：仅比较有值/无值状态。
    ///
    /// `AnyView` 不遵循 `Equatable`，SwiftUI 也未公开 unerase API。
    /// 保守近似：状态相同（均为 nil 或均为非 nil）即跳过赋值，避免装配流程
    /// 重复注入导致的无意义刷新；需要强制替换时先传 nil 再传新值。
    private func isSameView(_ lhs: AnyView?, _ rhs: AnyView?) -> Bool {
        (lhs == nil) == (rhs == nil)
    }
}
