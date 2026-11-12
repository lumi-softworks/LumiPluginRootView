import KernelCore
import ProviderRootView
import SwiftUI
import Testing
@testable import PluginRootView

/// 可配置根视图 provider 与插件在真实 Kernel 生命周期下的行为。
@Suite("ConfigurableRootViewProviding")
@MainActor
struct ConfigurableRootViewProvidingTests {
    @Test("provider 必须能产出根视图")
    func providerBuildsRootView() {
        let provider = ConfigurableRootViewProviding(layout: .toolbarWithMystiqueBackground)

        #expect(provider.makeRootView() != nil)
    }

    @Test("默认布局是最简形态：不显示工具栏、不铺背景")
    func minimalLayoutHasNoToolbarAndNoBackground() {
        let layout = RootViewLayoutConfiguration.minimal

        #expect(!layout.showsToolbar)
        #expect(!layout.usesMystiqueBackground)
    }

    @Test("工具栏 + 神秘背景布局打开对应开关")
    func toolbarWithMystiqueBackgroundEnablesBoth() {
        let layout = RootViewLayoutConfiguration.toolbarWithMystiqueBackground

        #expect(layout.showsToolbar)
        #expect(layout.usesMystiqueBackground)
    }

    @Test("空态文案默认取共享包的本地化文案")
    func emptyStateTitleDefaultsToSharedLocalization() {
        let layout = RootViewLayoutConfiguration.minimal

        #expect(layout.emptyStateTitle == RootContentComposer.defaultEmptyStateTitle)
    }

    @Test("宿主可覆盖空态文案")
    func hostCanOverrideEmptyStateTitle() {
        let layout = RootViewLayoutConfiguration(emptyStateTitle: "自定义空态")

        #expect(layout.emptyStateTitle == "自定义空态")
    }

    @Test("生命周期走真实 Kernel 流程：策略为 .alwaysOn，必然执行 onBoot")
    func kernelStartRegistersRootViewProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = RootViewPlugin(
            configuration: .lumi,
            provider: ConfigurableRootViewProviding(layout: .toolbarWithMystiqueBackground)
        )

        try kernel.start(plugins: [plugin])

        #expect(kernel.isProviderRegistered((any RootViewProviding).self))
        #expect(
            kernel.resolveProvider((any RootViewProviding).self)
                is ConfigurableRootViewProviding
        )
    }

    @Test("关停会撤回 provider")
    func kernelStopWithdrawsRootViewProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.start(plugins: [RootViewPlugin()])

        try kernel.stop()

        #expect(kernel.resolveProvider((any RootViewProviding).self) == nil)
    }

    @Test("配置里的布局会传给 provider")
    func pluginPassesLayoutToProvider() throws {
        let configuration = RootViewPluginConfiguration(
            pluginID: "com.example.plugin.root-view",
            layout: .toolbarWithMystiqueBackground
        )
        let plugin = RootViewPlugin(
            configuration: configuration,
            provider: ConfigurableRootViewProviding(layout: configuration.layout)
        )

        #expect(plugin.configuration.layout.showsToolbar)
        #expect(plugin.configuration.layout.usesMystiqueBackground)
    }
}
