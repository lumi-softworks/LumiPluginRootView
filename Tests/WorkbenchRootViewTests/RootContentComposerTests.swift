import KernelCore
import ProviderRootView
import SwiftUI
import Testing
@testable import WorkbenchRootView

/// `RootContentComposer` 的决策逻辑可以脱离 SwiftUI 视图树直接断言。
@Suite("RootContentComposer")
@MainActor
struct RootContentComposerTests {
    // MARK: - 工具栏

    @Test("工具栏区域可见且已安装视图时渲染")
    func toolbarRendersWhenRegionVisibleAndViewInstalled() {
        let provider = DefaultRootViewProviding()
        provider.setToolbarView(AnyView(Text("toolbar")))

        #expect(RootContentComposer.shouldRenderToolbar(for: provider))
        #expect(RootContentComposer.toolbarSource(for: provider) != nil)
    }

    @Test("工具栏区域被隐藏时不渲染")
    func toolbarDoesNotRenderWhenRegionHidden() {
        let provider = DefaultRootViewProviding()
        provider.setToolbarView(AnyView(Text("toolbar")))
        provider.setRegionHidden(true, for: .toolbar)

        #expect(!RootContentComposer.shouldRenderToolbar(for: provider))
        #expect(RootContentComposer.toolbarSource(for: provider) == nil)
    }

    @Test("未安装工具栏视图时不渲染")
    func toolbarDoesNotRenderWithoutToolbarView() {
        let provider = DefaultRootViewProviding()

        #expect(!RootContentComposer.shouldRenderToolbar(for: provider))
    }

    // MARK: - 内容隐藏

    @Test("内容区默认可见")
    func contentIsVisibleByDefault() {
        #expect(!RootContentComposer.isContentHidden(for: DefaultRootViewProviding()))
    }

    @Test("内容视图隐藏开关生效")
    func contentIsHiddenWhenContentViewHiddenFlagSet() {
        let provider = DefaultRootViewProviding()
        provider.setContentViewHidden(true)

        #expect(RootContentComposer.isContentHidden(for: provider))
        #expect(RootContentComposer.contentSource(for: provider) == .hidden)
    }

    @Test("内容区域被隐藏时生效")
    func contentIsHiddenWhenContentRegionHidden() {
        let provider = DefaultRootViewProviding()
        provider.setRegionHidden(true, for: .content)

        #expect(RootContentComposer.isContentHidden(for: provider))
        #expect(RootContentComposer.contentSource(for: provider) == .hidden)
    }

    @Test("两个隐藏开关任一生效都算隐藏")
    func contentIsHiddenWhenEitherSwitchTrips() {
        let provider = DefaultRootViewProviding()
        provider.setContentViewHidden(true)
        provider.setRegionHidden(false, for: .content)

        #expect(RootContentComposer.isContentHidden(for: provider))

        provider.setContentViewHidden(false)
        provider.setRegionHidden(true, for: .content)

        #expect(RootContentComposer.isContentHidden(for: provider))
    }

    @Test("取消隐藏会清除两个开关")
    func unhidingContentClearsBothSwitches() {
        let provider = DefaultRootViewProviding()
        provider.setContentViewHidden(true)
        provider.setRegionHidden(true, for: .content)

        provider.setContentViewHidden(false)
        provider.setRegionHidden(false, for: .content)

        #expect(!RootContentComposer.isContentHidden(for: provider))
    }

    // MARK: - 内容来源

    @Test("隐藏优先于内容贡献")
    func hiddenWinsOverInstalledContentView() {
        let provider = DefaultRootViewProviding()
        provider.setContentView(AnyView(Text("content")))
        provider.setContentViewHidden(true)

        #expect(RootContentComposer.contentSource(for: provider) == .hidden)
    }

    @Test("已注册内容贡献时来源为 contentView")
    func contentSourceIsContentViewWhenInstalled() {
        let provider = DefaultRootViewProviding()
        provider.setContentView(AnyView(Text("content")))

        #expect(RootContentComposer.contentSource(for: provider) == .contentView)
    }

    @Test("没有内容贡献时退化为空态")
    func contentSourceIsEmptyStateWhenNothingInstalled() {
        #expect(
            RootContentComposer.contentSource(for: DefaultRootViewProviding()) == .emptyState
        )
    }

    @Test("其它区域的可见性不影响内容来源")
    func contentSourceIgnoresUnrelatedRegionVisibility() {
        let provider = DefaultRootViewProviding()
        provider.setContentView(AnyView(Text("content")))
        provider.setRegionHidden(true, for: .toolbar)
        provider.setRegionHidden(true, for: .statusBar)

        #expect(RootContentComposer.contentSource(for: provider) == .contentView)
    }

    // MARK: - 视图构建

    @Test("三种来源都能构建出底图")
    func baseContentBuildsForEverySource() {
        let cases: [DefaultRootViewProviding] = [
            DefaultRootViewProviding(),
            { let p = DefaultRootViewProviding(); p.setContentView(AnyView(Text("c"))); return p }(),
            { let p = DefaultRootViewProviding(); p.setContentViewHidden(true); return p }(),
        ]

        for provider in cases {
            #expect(RootContentComposer.makeBaseContent(for: provider) != nil)
        }
    }

    // MARK: - Overlay

    @Test("overlay 套用在底图之上")
    func overlaysWrapBaseContent() {
        let provider = DefaultRootViewProviding()
        provider.setContentView(AnyView(Text("content")))
        provider.addOverlays([
            RootOverlayItem(id: "banner", order: 10) { content in
                VStack { content }
            },
        ])

        #expect(RootContentComposer.makeRootContent(for: provider) != nil)
        #expect(provider.overlays.count == 1)
    }

    @Test("无 overlay 时根内容就是底图")
    func rootContentWithoutOverlaysIsBaseContent() {
        let provider = DefaultRootViewProviding()
        provider.setContentView(AnyView(Text("content")))

        #expect(RootContentComposer.makeRootContent(for: provider) != nil)
        #expect(provider.overlays.isEmpty)
    }

    @Test("内容隐藏时 overlay 仍然生效")
    func hiddenContentStillAppliesOverlays() {
        let provider = DefaultRootViewProviding()
        provider.setContentViewHidden(true)
        provider.addOverlays([
            RootOverlayItem(id: "banner", order: 10) { content in
                VStack { content }
            },
        ])

        #expect(RootContentComposer.makeRootContent(for: provider) != nil)
    }

    @Test("多个 overlay 按 order 升序套用")
    func multipleOverlaysApplyInOrder() {
        let provider = DefaultRootViewProviding()
        provider.addOverlays([
            RootOverlayItem(id: "second", order: 20) { $0 },
            RootOverlayItem(id: "first", order: 10) { $0 },
        ])

        #expect(
            provider.overlays.map(\.id) == ["first", "second"],
            "overlay 应按 order 升序排列"
        )
        #expect(RootContentComposer.makeRootContent(for: provider) != nil)
    }

    // MARK: - 协议降级

    /// 仅实现 `makeRootView()`、其余走协议默认实现的 Provider
    /// 也必须走通同一条组装路径（插件被单独使用时的降级场景）。
    @Test("协议默认实现的 provider 也能走通组装路径")
    func composerWorksWithProtocolDefaultProvider() {
        let provider = MinimalRootViewProvider()

        #expect(!RootContentComposer.shouldRenderToolbar(for: provider))
        #expect(!RootContentComposer.isContentHidden(for: provider))
        #expect(RootContentComposer.contentSource(for: provider) == .emptyState)
        #expect(RootContentComposer.makeRootContent(for: provider) != nil)
    }

    @Test("可配置根视图 provider 也能走通组装路径")
    func composerWorksWithConfigurableProvider() {
        let provider = ConfigurableRootViewProviding(layout: .toolbarWithMystiqueBackground)

        #expect(RootContentComposer.contentSource(for: provider) == .emptyState)
        #expect(RootContentComposer.makeRootContent(for: provider) != nil)
    }
}

/// 仅实现 `makeRootView()`，其余成员走协议默认实现的 Provider。
@MainActor
private final class MinimalRootViewProvider: RootViewProviding {
    func makeRootView() -> AnyView { AnyView(Text("minimal")) }
}
