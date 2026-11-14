import KernelCore
import ProviderRootView
import SwiftUI
import Testing
@testable import WorkbenchRootView

/// `RootViewPlugin` 的契约是「onBoot 用自带 provider 替换内核默认注册、
/// onShutdown 注销」。它支持注入自定义 provider，因此可以完全脱离内核默认值测试。
@Suite("RootViewPlugin")
@MainActor
struct RootViewPluginTests {
    @Test("默认注入 DefaultRootViewProviding")
    func usesDefaultProviderByDefault() {
        let plugin = RootViewPlugin()
        #expect(plugin.provider is DefaultRootViewProviding)
    }

    @Test("支持注入自定义 provider")
    func acceptsInjectedProvider() {
        let custom = DefaultRootViewProviding()
        let plugin = RootViewPlugin(provider: custom)
        #expect(plugin.provider === custom)
    }

    @Test("onBoot 将注入的 provider 注册到内核")
    func onBootRegistersProvider() throws {
        let kernel = KernelCoreContainer()
        let custom = DefaultRootViewProviding()
        let plugin = RootViewPlugin(provider: custom)

        try plugin.onBoot(kernel: kernel)

        let resolved = try #require(kernel.resolveProvider((any RootViewProviding).self))
        #expect(resolved === custom)
    }

    @Test("onBoot 会替换内核已有的默认 provider")
    func onBootReplacesExistingProvider() throws {
        let kernel = KernelCoreContainer()
        let original = DefaultRootViewProviding()
        try kernel.registerProvider((any RootViewProviding).self, original)

        let custom = DefaultRootViewProviding()
        let plugin = RootViewPlugin(provider: custom)
        try plugin.onBoot(kernel: kernel)

        let resolved = try #require(kernel.resolveProvider((any RootViewProviding).self))
        #expect(resolved === custom)
        #expect(resolved !== original)
    }

    @Test("onShutdown 注销 provider")
    func onShutdownUnregistersProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = RootViewPlugin(provider: DefaultRootViewProviding())
        try plugin.onBoot(kernel: kernel)
        #expect(kernel.resolveProvider((any RootViewProviding).self) != nil)

        try plugin.onShutdown(kernel: kernel)
        #expect(kernel.resolveProvider((any RootViewProviding).self) == nil)
    }

    @Test("未 boot 时 onShutdown 是安全的空操作")
    func shutdownWithoutBootIsSafe() throws {
        let kernel = KernelCoreContainer()
        let plugin = RootViewPlugin()

        // 不应抛错
        try plugin.onShutdown(kernel: kernel)
        #expect(kernel.resolveProvider((any RootViewProviding).self) == nil)
    }

    @Test("重复 onShutdown 幂等")
    func repeatedShutdownIsIdempotent() throws {
        let kernel = KernelCoreContainer()
        let plugin = RootViewPlugin(provider: DefaultRootViewProviding())
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(kernel.resolveProvider((any RootViewProviding).self) == nil)
    }

    @Test("重复 onBoot 后仍只保留注入的 provider")
    func repeatedBootKeepsInjectedProvider() throws {
        let kernel = KernelCoreContainer()
        let custom = DefaultRootViewProviding()
        let plugin = RootViewPlugin(provider: custom)

        try plugin.onBoot(kernel: kernel)
        try plugin.onBoot(kernel: kernel)

        let resolved = try #require(kernel.resolveProvider((any RootViewProviding).self))
        #expect(resolved === custom)
    }

    @Test("插件元数据与固定 pluginID 一致")
    func metadataMatchesPluginID() {
        let plugin = RootViewPlugin()
        #expect(plugin.id == plugin.configuration.pluginID)
        #expect(plugin.metadata.id == plugin.configuration.pluginID)
    }

    /// 分类必须是 `.general`。
    ///
    /// `PluginMetadata.category` 的默认值就是 `.general`，Wakey 迁移前的本地
    /// 包没有显式传 category，因此落在这个默认值上。插件管理页按 category
    /// 分组展示，分类漂移会让根视图插件从「通用」挪到「系统」分组。
    @Test("插件分类保持 .general")
    func metadataCategoryStaysGeneral() {
        #expect(RootViewPlugin().metadata.category == .general)
        #expect(RootViewPlugin(configuration: .wakey).metadata.category == .general)
        #expect(RootViewPlugin(configuration: .juiceNote).metadata.category == .general)
        #expect(RootViewPlugin(configuration: .kuzee).metadata.category == .general)
    }

    /// 根视图是应用外壳的最后一道防线：一旦被关闭应用将没有窗口，
    /// 因此策略必须是 alwaysOn 且不可配置。
    @Test("插件策略为 alwaysOn 且不可配置")
    func metadataIsAlwaysOnAndNotConfigurable() {
        let policy = RootViewPlugin().metadata.policy

        #expect(policy == .alwaysOn)
        #expect(!policy.isConfigurable)
    }

    /// 根视图要先于所有内容插件就位，所以 order 必须排在最前。
    @Test("根视图插件的启动顺序早于其它插件")
    func pluginBootsBeforeOtherPlugins() {
        #expect(RootViewPlugin().order == 0)
        #expect(RootViewPlugin(configuration: .juiceNote).order == -1_000)
        #expect(RootViewPlugin(configuration: .kuzee).order == -1_000)
    }

    @Test("可经 kernel.start 启动")
    func startsViaKernel() throws {
        let kernel = KernelCoreContainer()
        let custom = DefaultRootViewProviding()
        let plugin = RootViewPlugin(provider: custom)

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id))
        let resolved = try #require(kernel.resolveProvider((any RootViewProviding).self))
        #expect(resolved === custom)
    }
}
