import Foundation

/// 根视图插件的品牌配置。
///
/// 共享远程包不能把宿主品牌写死在代码里：插件 id、插件名、描述、启动顺序与
/// 日志子系统都属于「谁的插件」，必须由宿主在装配时注入。
///
/// 插件 id 同时是插件启用状态的存储 key。宿主必须传入自己的历史 id，
/// 否则用户的既有状态与插件专属数据目录会与旧版本脱节。
///
/// - `pluginID`：插件唯一标识，例如 `com.coffic.wakey.plugin.root-view`。
/// - `pluginName`：插件在插件管理页展示的名称。
/// - `pluginDescription`：插件在插件管理页展示的描述。
/// - `order`：插件启动顺序，数值越小越先 `onBoot`。
///   根视图必须早于任何向 `RootViewProviding` 贡献内容的插件启动。
/// - `loggerSubsystem`：日志子系统。宿主的磁盘日志插件按 subsystem 前缀
///   收集日志，写错会让插件日志无法落盘。
public struct RootViewPluginConfiguration: Sendable, Equatable {
    /// 插件唯一标识。
    public let pluginID: String

    /// 插件展示名称。
    public let pluginName: String

    /// 插件展示描述。
    public let pluginDescription: String

    /// 插件启动顺序。
    public let order: Int

    /// 日志子系统。
    public let loggerSubsystem: String

    public init(
        pluginID: String,
        pluginName: String = "Root View",
        pluginDescription: String = "Provides the application's root layout",
        order: Int = 0,
        loggerSubsystem: String? = nil
    ) {
        self.pluginID = pluginID
        self.pluginName = pluginName
        self.pluginDescription = pluginDescription
        self.order = order
        self.loggerSubsystem = loggerSubsystem ?? pluginID
    }

    /// Lumi 品牌的默认配置。
    public static let lumi = Self(
        pluginID: "com.coffic.lumi.plugin.root-view",
        pluginName: "Root View",
        pluginDescription: "Provides the application's root layout",
        order: 0,
        loggerSubsystem: "com.coffic.lumi.plugin.root-view"
    )

    /// Wakey 品牌的默认配置。
    ///
    /// 与 Wakey 仓库里迁移前的本地包逐字一致：插件 id、名称、描述与启动
    /// 顺序都保持不变，避免迁移后插件管理页展示变化、且既有插件状态继续生效。
    public static let wakey = Self(
        pluginID: "com.coffic.wakey.plugin.root-view",
        pluginName: "Root View",
        pluginDescription: "Provides Wakey's root view regions",
        order: -1,
        loggerSubsystem: "com.coffic.wakey.plugin.root-view"
    )
}
