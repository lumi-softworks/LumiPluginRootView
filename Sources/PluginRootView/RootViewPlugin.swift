import KernelCore
import LumiLoggingKit
import OSLog
import ProviderRootView

/// 根视图插件：把宿主选择的 `RootViewProviding` 实现接入 KernelCore。
///
/// 共享的 provider（`ProviderRootView`）拥有根区域与 overlay 状态；本插件只
/// 负责「注册 / 注销」这一个生命周期动作。宿主在装配时注入自己的品牌配置
/// 与 provider 实现。
///
/// 契约：
/// - `onBoot` 用自带 provider 替换内核默认注册（先注销再注册，避免
///   `providerAlreadyRegistered`）；
/// - `onShutdown` 注销 provider，使内核不再能解析到 `RootViewProviding`。
@MainActor
public final class RootViewPlugin: SuperPlugin, SuperLog {
    nonisolated public static let emoji = "🏠"
    nonisolated public static let verbose = false

    /// 日志子系统。跟随宿主注入的品牌配置，便于在系统日志中区分品牌。
    public let logger: Logger

    /// 插件唯一标识。
    public let id: String

    /// 插件启动顺序。
    public let order: Int

    /// 插件元数据。
    public let metadata: PluginMetadata

    /// 插件自带的根视图 provider。
    public let provider: any RootViewProviding

    /// 品牌配置。宿主可读取它做接线校验。
    public let configuration: RootViewPluginConfiguration

    /// 创建根视图插件。
    ///
    /// - Parameters:
    ///   - configuration: 宿主品牌配置（插件 id、名称、描述、顺序、日志子系统）。
    ///   - provider: 根视图 provider 实现。默认使用 `DefaultRootViewProviding`，
    ///     需要自定义根布局的宿主可注入自己的 `DefaultRootViewProviding` 子类。
    public init(
        configuration: RootViewPluginConfiguration = .lumi,
        provider: any RootViewProviding = DefaultRootViewProviding()
    ) {
        self.configuration = configuration
        self.id = configuration.pluginID
        self.order = configuration.order
        self.metadata = PluginMetadata(
            id: configuration.pluginID,
            name: configuration.pluginName,
            description: configuration.pluginDescription,
            stage: .stable,
            policy: .alwaysOn
        )
        self.provider = provider
        self.logger = Logger(subsystem: configuration.loggerSubsystem, category: "RootView")
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        // 允许宿主在启动前注册的实现被本插件的显式选择覆盖，
        // 同时保证重启内核时不会触发 providerAlreadyRegistered。
        kernel.unregisterProvider((any RootViewProviding).self)
        try kernel.registerProvider((any RootViewProviding).self, provider)

        if Self.verbose {
            self.logger.info("\(Self.t)Registered RootViewProviding for '\(self.id, privacy: .public)'")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.unregisterProvider((any RootViewProviding).self)

        if Self.verbose {
            self.logger.info("\(Self.t)Unregistered RootViewProviding for '\(self.id, privacy: .public)'")
        }
    }
}
