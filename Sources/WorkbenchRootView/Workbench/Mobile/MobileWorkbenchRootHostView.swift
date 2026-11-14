import LumiUI
import ProviderActivityBar
import ProviderRootView
import SwiftUI

/// 移动端工作台：内容区 + 底部标签栏。
///
/// 与桌面版的区别：
/// - 不渲染顶部工具栏（iOS 的工具栏由导航栏承载）；
/// - 不渲染 Rail：笔记树等内容由工作区自己作为导航的根视图呈现；
/// - ActivityBar 的条目呈现为底部标签栏，点击即切换工作区。
@MainActor
struct MobileWorkbenchRootHostView: View {
    @ObservedObject var provider: WorkbenchRootViewProviding

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                MobileActivityBarContainer(provider: provider.activityBarProvider)
            }
            .modifier(
                WorkbenchBackgroundModifier(
                    usesThemeBackground: provider.layout.usesThemeBackground,
                    usesMystiqueBackground: provider.layout.usesMystiqueBackground
                )
            )
    }

    @ViewBuilder
    private var content: some View {
        if provider.isContentViewHidden {
            Color.clear
        } else if let contentView = provider.contentView {
            contentView
        } else if provider.layout.showsWelcomePlaceholder {
            WorkbenchWelcomeView(layout: provider.layout)
        } else {
            Color.clear
        }
    }
}

/// 底部标签栏容器：只让标签栏本身随 ActivityBar 事件重建。
///
/// 不能把重建 identity 加在根视图上，否则切 tab 时内容区也会被重建，
/// 工作区的导航栈与滚动位置会一并丢失。
@MainActor
private struct MobileActivityBarContainer: View {
    let provider: (any ActivityBarProviding)?
    @State private var revision = 0
    @State private var observerHandle: (any ActivityBarObserverHandle)?

    var body: some View {
        Group {
            if let provider {
                let model = MobileActivityBarModel(
                    items: provider.items,
                    activeItemID: provider.activeItemID,
                    isVisible: provider.shouldDisplayActivityBar
                )
                if model.shouldShowBar {
                    MobileActivityBarView(model: model) { id in
                        provider.activateItem(id: id)
                    }
                }
            }
        }
        .id(revision)
        .onAppear {
            guard observerHandle == nil, let provider else { return }
            observerHandle = provider.addActivityBarObserver { _ in
                revision += 1
            }
        }
        .onDisappear {
            observerHandle?.cancel()
            observerHandle = nil
        }
    }
}
