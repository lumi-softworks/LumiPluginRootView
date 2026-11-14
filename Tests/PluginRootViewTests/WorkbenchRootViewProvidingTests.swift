import ProviderActivityBar
import ProviderRailView
import ProviderRootView
import SwiftUI
import Testing
@testable import PluginRootView

/// `WorkbenchRootViewProviding` 的区域联动语义。
@Suite("WorkbenchRootViewProviding")
@MainActor
struct WorkbenchRootViewProvidingTests {
    @Test("provider 必须能产出根视图")
    func providerBuildsRootView() {
        let provider = WorkbenchRootViewProviding()
        _ = provider.makeRootView()
    }

    @Test("标准布局默认打开工具栏、欢迎占位与主题背景")
    func standardLayoutDefaults() {
        let layout = WorkbenchLayoutConfiguration.standard
        #expect(layout.showsToolbar)
        #expect(layout.showsWelcomePlaceholder)
        #expect(layout.usesThemeBackground)
        #expect(!layout.welcomeTitle.isEmpty)
        #expect(!layout.welcomeMessage.isEmpty)
    }

    @Test("无工具栏布局关闭工具栏")
    func withoutToolbarLayout() {
        #expect(!WorkbenchLayoutConfiguration.withoutToolbar.showsToolbar)
    }

    @Test("绑定 Rail 后 hasRailContent 跟随可见标签")
    func hasRailContentFollowsRailTabs() {
        let provider = WorkbenchRootViewProviding()
        let rail = DefaultRailViewProviding()

        provider.bindRailViewVisibility(to: rail)
        #expect(provider.hasRailContent == false)

        rail.addTabs([
            RailTabItem(id: "t1", category: .system, title: "Tab", systemImage: "doc", order: 0) {
                Text("Tab")
            }
        ])
        #expect(provider.hasRailContent)
        #expect(provider.isRailViewVisible)
    }

    @Test("移除 Rail 视图会隐藏 Rail，恢复视图时回到原有可见性")
    func railViewRemovalHidesAndRestoresVisibility() {
        let provider = WorkbenchRootViewProviding()
        let railView = AnyView(Text("rail"))

        provider.setRailView(railView)
        #expect(provider.isRailViewVisible)

        provider.setRailView(nil)
        #expect(provider.isRailViewVisible == false)

        provider.setRailView(railView)
        #expect(provider.isRailViewVisible)
    }

    @Test("未注入内容时没有活跃内容，注入后变为活跃")
    func hasActiveContentFollowsContentView() {
        let provider = WorkbenchRootViewProviding()
        #expect(provider.hasActiveContent == false)

        provider.setContentView(AnyView(Text("content")))
        #expect(provider.hasActiveContent)
    }

    #if os(macOS)
    @Test("注入 ActivityBar provider 时同时挂载竖栏视图")
    func activityBarProviderInjectsDesktopView() {
        let provider = WorkbenchRootViewProviding()
        let bar = DefaultActivityBarProviding()
        bar.addItems([
            ActivityBarItem(id: "a", title: "A", systemImage: "gear"),
            ActivityBarItem(id: "b", title: "B", systemImage: "doc")
        ])

        provider.setActivityBarProvider(bar)

        #expect(provider.activityBarProvider != nil)
        #expect(provider.activityBarView != nil)
    }
    #endif
}
