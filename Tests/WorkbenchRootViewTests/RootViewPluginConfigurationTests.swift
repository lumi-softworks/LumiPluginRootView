import Testing
@testable import WorkbenchRootView

/// 品牌配置是共享包与宿主之间唯一的耦合点：取值必须逐字稳定，
/// 否则插件管理页展示、既有插件启用状态与日志落盘都会漂移。
@Suite("RootViewPluginConfiguration")
struct RootViewPluginConfigurationTests {
    @Test("Lumi 品牌取值为历史值")
    func lumiConfigurationKeepsHistoricalValues() {
        let configuration = RootViewPluginConfiguration.lumi
        #expect(configuration.pluginID == "com.coffic.lumi.plugin.root-view")
        #expect(configuration.pluginName == "Root View")
        #expect(configuration.pluginDescription == "Provides the application's root layout")
        #expect(configuration.order == 0)
        #expect(configuration.loggerSubsystem == "com.coffic.lumi.plugin.root-view")
    }

    @Test("Wakey 品牌取值为历史值")
    func wakeyConfigurationKeepsHistoricalValues() {
        let configuration = RootViewPluginConfiguration.wakey
        #expect(configuration.pluginID == "com.coffic.wakey.plugin.root-view")
        #expect(configuration.pluginName == "Root View")
        #expect(configuration.pluginDescription == "Provides Wakey's root view regions")
        #expect(configuration.order == -1)
        #expect(configuration.loggerSubsystem == "com.coffic.wakey.plugin.root-view")
    }

    @Test("未显式指定日志子系统时回退到插件 id")
    func loggerSubsystemFallsBackToPluginID() {
        let configuration = RootViewPluginConfiguration(pluginID: "com.example.plugin.root-view")
        #expect(configuration.loggerSubsystem == "com.example.plugin.root-view")
    }

    @Test("配置是 Equatable 的值类型")
    func configurationIsEquatable() {
        let configuration = RootViewPluginConfiguration(pluginID: "com.example.plugin.root-view")
        #expect(configuration == RootViewPluginConfiguration(pluginID: "com.example.plugin.root-view"))
        #expect(configuration != RootViewPluginConfiguration(pluginID: "com.example.other"))
    }

    @Test("JuiceNote 品牌取值为历史值")
    func juiceNoteConfigurationKeepsHistoricalValues() {
        let configuration = RootViewPluginConfiguration.juiceNote
        #expect(configuration.pluginID == "com.coffic.juicenote.plugin.root-view")
        #expect(configuration.pluginName == "Root View")
        #expect(configuration.pluginDescription == "Provides JuiceNote's application layout")
        #expect(configuration.order == -1_000)
        #expect(configuration.loggerSubsystem == "com.coffic.juicenote.plugin.root-view")
        #expect(configuration.layout.showsToolbar)
        #expect(configuration.layout.usesMystiqueBackground)
    }

    @Test("Kuzee 品牌取值为历史值")
    func kuzeeConfigurationKeepsHistoricalValues() {
        let configuration = RootViewPluginConfiguration.kuzee
        #expect(configuration.pluginID == "com.coffic.kuzee.plugin.root-view")
        #expect(configuration.pluginName == "Root View")
        #expect(configuration.pluginDescription == "Provides Kuzee's application layout")
        #expect(configuration.order == -1_000)
        #expect(configuration.loggerSubsystem == "com.coffic.kuzee.plugin.root-view")
        #expect(configuration.layout.showsToolbar)
        #expect(configuration.layout.usesMystiqueBackground)
    }
}
