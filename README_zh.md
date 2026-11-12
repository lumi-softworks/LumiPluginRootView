# LumiPluginRootView

📖 [English](README.md) | 中文版

根视图插件的共享远程包，由 Lumi / Wakey 等 Lumi 家族兄弟应用装配。

> 本插件不依赖任何其它插件。根视图能力本身位于 `ProviderRootView`
> （来自 `LumiProviders`）；本包只负责围绕它的插件生命周期。

## 包信息

- manifest 包名：`LumiPluginRootView`（与仓库名一致）
- product / target：`PluginRootView`
- 平台：macOS 14+ / iOS 17+
- Swift tools：6.0

## 命名约定

Lumi Softworks 远程插件包统一遵循此约定：

| 仓库 | manifest `name:` | product / target |
| --- | --- | --- |
| `LumiPluginRootView` | `LumiPluginRootView` | `PluginRootView` |
| `LumiPluginAbout` | `LumiPluginAbout` | `PluginAbout` |
| `LumiPluginFileLog` | `LumiPluginFileLog` | `PluginFileLog` |

原因：Xcode 的依赖列表显示的是上游 manifest 的 `Package(name:)`，而非仓库名。
manifest 包名不带 `Lumi` 前缀时，用户在 Xcode 里就看不到这个前缀了。仓库名与
包名保持一致，消费方 `.product(name:package:)` 的 `package:` 参数按 URL basename
匹配，因此必须是仓库名。

## 提供的能力

- `RootViewPlugin`：把一个 `RootViewProviding` 实现注册进内核。
- 替换式注册：`onBoot` 先注销内核默认 provider，再注册插件自带的 provider，
  宿主因此可以确定性地选择自己的根布局。
- 幂等关闭：`onShutdown` 注销 provider，重复调用安全无副作用。
- provider 可注入：需要自定义根布局的宿主传入自己的 `DefaultRootViewProviding`
  子类；只需要通用贡献 API 的宿主直接使用默认实现。

## 依赖与接入

```swift
dependencies: [
    .package(url: "https://github.com/lumi-softworks/LumiPluginRootView.git", from: "1.0.0")
]
```

在宿主 Factory target 中加入 product：

```swift
.product(name: "PluginRootView", package: "LumiPluginRootView")
```

并在插件工厂中装配：

```swift
import PluginRootView

RootViewPlugin(configuration: .wakey)
```

## 品牌配置

共享包不写死任何宿主品牌。宿主通过 `RootViewPluginConfiguration` 注入自己的身份：

| 字段 | 作用 | 默认值（Lumi） |
| --- | --- | --- |
| `pluginID` | 插件标识 —— 决定启用状态与插件数据目录 | `com.coffic.lumi.plugin.root-view` |
| `pluginName` | 插件管理页展示的名称 | `Root View` |
| `pluginDescription` | 插件管理页展示的描述 | `Provides the application's root layout` |
| `order` | 启动顺序 —— 根视图必须早于向其贡献内容的插件启动 | `0` |
| `loggerSubsystem` | 日志子系统 —— 宿主的磁盘日志插件按 subsystem 前缀收集日志 | `com.coffic.lumi.plugin.root-view` |

`RootViewPluginConfiguration.lumi` 与 `RootViewPluginConfiguration.wakey`
已为现有两个宿主提供。**宿主必须保持自己的历史插件 id** —— 否则用户已保存的
启用状态与插件数据目录会与旧版本脱节：

```swift
RootViewPlugin(
    configuration: RootViewPluginConfiguration(
        pluginID: "com.coffic.wakey.plugin.root-view",
        pluginName: "Root View",
        pluginDescription: "Provides Wakey's root view regions",
        order: -1,
        loggerSubsystem: "com.coffic.wakey.plugin.root-view"
    )
)
```

### 自定义根布局

默认 provider 只用通用贡献 API 渲染，不含平台专属布局。需要 macOS 或 iOS
专属组合的宿主注入自己的子类：

```swift
@MainActor
final class MyAppRootViewProvider: DefaultRootViewProviding {
    override func makeRootView() -> AnyView {
        AnyView(MyRootHostView(provider: self))
    }
}

RootViewPlugin(configuration: .lumi, provider: MyAppRootViewProvider())
```

本插件不规定布局 —— 它只保证内核解析到的是宿主选择的 provider。

## 启动顺序

根视图插件必须**先于**任何向根视图贡献内容的插件启动，否则那些贡献会落到
即将被替换掉的 provider 里。请据此设置 `order`（目前 Lumi 为 `0`、Wakey 为
`-1`，都早于业务插件）。

## 根视图布局

`RootViewLayoutConfiguration` 描述共享根视图的组合方式：

| 字段 | 作用 | 默认值 |
| --- | --- | --- |
| `showsToolbar` | 是否在顶部渲染工具栏区域（仅 macOS） | `false` |
| `usesMystiqueBackground` | 是否在根视图后铺主题渐变背景 | `false` |
| `emptyStateTitle` | 内容区没有贡献时的空态文案 | 本包本地化的「当前没有可显示的内容」 |

内置两个预设：

- `RootViewLayoutConfiguration.minimal` —— 只有内容区；
- `RootViewLayoutConfiguration.toolbarWithMystiqueBackground` —— 顶部工具栏 + 主题渐变。

需要该布局的宿主注入 `ConfigurableRootViewProviding`：

```swift
RootViewPlugin(
    configuration: .juiceNote,
    provider: ConfigurableRootViewProviding(layout: .toolbarWithMystiqueBackground)
)
```

本包为兄弟应用内置了 `.lumi`、`.wakey`、`.juiceNote`、`.kuzee` 四套预设。
每套预设都保留各自宿主的历史插件 id、启动顺序与布局，因此宿主迁到本包后
渲染结果不变。

## 本地化

空态文案的字符串目录提供英文、简体中文、繁体中文（`en` / `zh-Hans` /
`zh-Hant`）。宿主不能覆盖这份字符串目录 —— 它是唯一事实来源 —— 但可以
通过 `emptyStateTitle` 传入自己的文案。

## 测试

```sh
swift test
```
