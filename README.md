# LumiPluginRootView

📖 English | [中文版](README_zh.md)

Shared remote package for the "Root View" plugin, assembled by Lumi family sibling apps such as Lumi and Wakey.

> This plugin depends on no other plugins. The root-view capability itself lives in `ProviderRootView` (from `LumiProviders`); this package only owns the plugin lifecycle around it.

## Package

- Manifest package name: `LumiPluginRootView` (matches the repository name)
- Product / Target: `WorkbenchRootView` (module name kept distinct from host-local `PluginRootView` modules)
- Platform: macOS 14+ / iOS 17+
- Swift tools: 6.0

## Naming Convention

Lumi Softworks remote plugin packages follow this convention uniformly:

| Repository | manifest `name:` | product / target |
| --- | --- | --- |
| `LumiPluginRootView` | `LumiPluginRootView` | `WorkbenchRootView` |
| `LumiPluginAbout` | `LumiPluginAbout` | `PluginAbout` |
| `LumiPluginFileLog` | `LumiPluginFileLog` | `PluginFileLog` |

Why: Xcode's package dependency list shows the upstream manifest's `Package(name:)`, not the repository name. Without the `Lumi` prefix in the manifest package name, users would not see the prefix in Xcode. The repository name stays consistent with the package name, and the consumer's `.product(name:package:)` `package:` argument matches the URL basename, so it must be the repository name.

## What It Provides

- A `RootViewPlugin` that registers a `RootViewProviding` implementation into the kernel.
- Replacement semantics: `onBoot` unregisters the kernel's default provider and registers the plugin's own one, so a host can pick its root layout deterministically.
- Idempotent shutdown: `onShutdown` unregisters the provider, and repeated calls are safe.
- An injectable provider: hosts that need a custom root layout pass their own `DefaultRootViewProviding` subclass; hosts that need the plain contribution API get `DefaultRootViewProviding` for free.
- `RootContentComposer`: the shared content-assembly decisions (toolbar visibility, content source, overlay order) — pure functions that can be asserted without building a SwiftUI view tree.
- `ConfigurableRootViewProviding`: a ready-made root layout with an optional top toolbar, an optional theme gradient background, and an empty-state placeholder.

## Workbench Layout

`WorkbenchRootViewProviding` is the ready-made multi-workspace shell used by apps that expose several top-level features:

- macOS: top toolbar + ActivityBar column + rail (resizable sidebar) + content area (optional content header / footer / trailing pane).
- iOS: content area + bottom tab bar. Each `ActivityBarItem` becomes one tab; the rail is not rendered on iOS because workspaces own their own navigation stack.

Injection (typically in the host's view factory):

```swift
let root = WorkbenchRootViewProviding(layout: .standard)

root.setToolbarView(toolbar.makeToolbarView())
root.setActivityBarProvider(activityBar)          // macOS: renders makeActivityBarView(); iOS: renders items as tabs
root.setRailView(rail.makeRailView())
root.bindRailViewVisibility(to: rail)             // rail visibility follows hasVisibleTabs
root.bindRailViewWidth(to: rail, onResize: rail.saveCurrentWidth)
root.setContentView(contentView.makeContentView())
```

Behaviour that hosts rely on:

- The ActivityBar is hidden when it has fewer than two items (`shouldDisplayActivityBar`).
- `hasRailContent` distinguishes "the host allows the rail" from "the rail actually has tabs"; the split view is rebuilt when content appears, because an empty `HSplitView` pane collapses permanently.
- Removing the rail view (`setRailView(nil)`) hides it and remembers the previous visibility, so a workspace without a rail can restore the shared one on deactivation.
- Content injection only takes effect on `nil` → non-`nil` transitions; plugins must clear their content on deactivation (the same contract as Lumi's plugins).

Customize the welcome placeholder with `WorkbenchLayoutConfiguration` (`welcomeTitle`, `welcomeMessage`, `showsWelcomePlaceholder`, `showsToolbar`, `usesThemeBackground`, `usesMystiqueBackground`). Use `ConfigurableRootViewProviding` instead when the host only needs "toolbar + content".

## Dependencies and Integration

```swift
dependencies: [
    .package(url: "https://github.com/lumi-softworks/LumiPluginRootView.git", from: "1.3.0")
]
```

Add the product to the host Factory target:

```swift
.product(name: "WorkbenchRootView", package: "LumiPluginRootView")
```

And assemble it in the plugin factory:

```swift
import WorkbenchRootView

RootViewPlugin(configuration: .wakey)
```

## Brand Configuration

The shared package hardcodes no host brand. The host injects its own identity through `RootViewPluginConfiguration`:

| Field | Purpose | Default (Lumi) |
| --- | --- | --- |
| `pluginID` | Plugin identity — drives the enabled state and the plugin data directory | `com.coffic.lumi.plugin.root-view` |
| `pluginName` | Name shown in the plugin management page | `Root View` |
| `pluginDescription` | Description shown in the plugin management page | `Provides the application's root layout` |
| `order` | Boot order — the root view must start before any plugin that contributes to it | `0` |
| `loggerSubsystem` | Logger subsystem — the host's disk-log plugin collects logs by subsystem prefix | `com.coffic.lumi.plugin.root-view` |

`RootViewPluginConfiguration.lumi` and `RootViewPluginConfiguration.wakey` are provided for the two existing hosts. **Hosts must keep their historical plugin ID** — otherwise the user's saved enabled state and the plugin data directory are orphaned:

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

### Custom root layouts

The default provider renders the shared contribution API with no platform-specific layout. A host that needs a macOS- or iOS-specific composition injects its own subclass:

```swift
@MainActor
final class MyAppRootViewProvider: DefaultRootViewProviding {
    override func makeRootView() -> AnyView {
        AnyView(MyRootHostView(provider: self))
    }
}

RootViewPlugin(configuration: .lumi, provider: MyAppRootViewProvider())
```

The plugin does not prescribe a layout — it only guarantees that the kernel resolves the provider the host chose.

## Boot Order

The root-view plugin must start **before** any plugin that contributes content to the root view, otherwise those contributions land in a provider that is about to be replaced. Set `order` accordingly (the shipped defaults are `0` for Lumi and `-1` for Wakey, both of which run before the business plugins).

## Root Layout

`RootViewLayoutConfiguration` describes how the shared root view is composed:

| Field | Purpose | Default |
| --- | --- | --- |
| `showsToolbar` | Render the toolbar region at the top (macOS only) | `false` |
| `usesMystiqueBackground` | Paint the theme gradient behind the root view | `false` |
| `emptyStateTitle` | Title shown when the content region has no contribution | the package's localized "No content to display" |

Two ready-made presets exist:

- `RootViewLayoutConfiguration.minimal` — content region only.
- `RootViewLayoutConfiguration.toolbarWithMystiqueBackground` — top toolbar plus the theme gradient.

A host that wants this layout injects `ConfigurableRootViewProviding`:

```swift
RootViewPlugin(
    configuration: .juiceNote,
    provider: ConfigurableRootViewProviding(layout: .toolbarWithMystiqueBackground)
)
```

The package ships presets for the sibling apps: `.lumi`, `.wakey`, `.juiceNote` and `.kuzee`. Each preset keeps its host's historical plugin ID, boot order and layout, so migrating a host to this package does not change what it renders.

## Localization

The string catalog ships English, Simplified Chinese, and Traditional Chinese (`en` / `zh-Hans` / `zh-Hant`) for the empty-state title. Hosts cannot override that string catalog — it is the single source of truth — but they can pass their own `emptyStateTitle`.

## Testing

```sh
swift test
```
