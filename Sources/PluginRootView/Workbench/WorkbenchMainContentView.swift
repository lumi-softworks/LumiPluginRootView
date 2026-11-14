import LumiUI
import ProviderRootView
import SwiftUI

/// 工作台的内容区（可选 content header / footer 与 trailing pane）。
@MainActor
struct WorkbenchMainContentView: View {
    let contentHeaderView: AnyView?
    let isContentHeaderViewHidden: Bool
    let contentView: AnyView?
    let contentFooterView: AnyView?
    let isContentFooterViewHidden: Bool
    let contentFooterHeight: ContentFooterHeight
    let onContentFooterResize: (@MainActor (CGFloat) -> Void)?
    let isContentViewHidden: Bool
    @ObservedObject var trailingPane: RootViewPane

    init(
        contentHeaderView: AnyView?,
        isContentHeaderViewHidden: Bool,
        contentView: AnyView?,
        contentFooterView: AnyView?,
        isContentFooterViewHidden: Bool = false,
        contentFooterHeight: ContentFooterHeight = .standard,
        onContentFooterResize: (@MainActor (CGFloat) -> Void)? = nil,
        isContentViewHidden: Bool,
        trailingPane: RootViewPane?
    ) {
        self.contentHeaderView = contentHeaderView
        self.isContentHeaderViewHidden = isContentHeaderViewHidden
        self.contentView = contentView
        self.contentFooterView = contentFooterView
        self.isContentFooterViewHidden = isContentFooterViewHidden
        self.contentFooterHeight = contentFooterHeight
        self.onContentFooterResize = onContentFooterResize
        self.isContentViewHidden = isContentViewHidden
        _trailingPane = ObservedObject(wrappedValue: trailingPane ?? RootViewPane(
            id: "workbench.empty",
            isVisible: false,
            content: AnyView(EmptyView())
        ))
    }

    private var mainContent: AnyView {
        contentView ?? AnyView(WorkbenchContentPlaceholderView())
    }

    @ViewBuilder
    private var contentWithHeaderAndFooter: some View {
        if let contentFooterView, !isContentFooterViewHidden {
            #if os(macOS)
            VSplitView {
                contentWithHeader
                    .frame(minHeight: 0, maxHeight: .infinity)
                    .appSplitDivider(
                        .bottom,
                        initialTrailingSize: contentFooterHeight.idealHeight,
                        resizeTarget: .trailing,
                        onResize: onContentFooterResize
                    )
                contentFooterView
                    .frame(
                        minHeight: contentFooterHeight.minHeight,
                        idealHeight: contentFooterHeight.idealHeight,
                        maxHeight: contentFooterHeight.maxHeight
                    )
                    .zIndex(1)
            }
            #else
            VStack(spacing: 0) {
                contentWithHeader
                contentFooterView
            }
            #endif
        } else if contentHeaderView != nil && !isContentHeaderViewHidden {
            contentWithHeader
        } else {
            mainContent
        }
    }

    @ViewBuilder
    private var contentWithHeader: some View {
        VStack(spacing: 0) {
            if let contentHeaderView, !isContentHeaderViewHidden {
                contentHeaderView
                    .zIndex(1)
            }
            mainContent
                // AppKit-backed editors can draw floating subviews (for example,
                // the line-number gutter) outside their SwiftUI layout bounds.
                // Keep those subviews below the fixed content header while scrolling.
                .clipped()
        }
    }

    /// 是否存在有意义的主内容（header 或 content 任一被注入）。
    private var hasMainContent: Bool {
        (contentHeaderView != nil && !isContentHeaderViewHidden)
            || contentView != nil
            || (contentFooterView != nil && !isContentFooterViewHidden)
    }

    var body: some View {
        Group {
            if isContentViewHidden {
                // 主内容区被完全隐藏：不渲染内容区，trailing pane 独占全部空间。
                if trailingPane.isVisible {
                    trailingPane.content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if trailingPane.isVisible {
                if hasMainContent {
                    #if os(macOS)
                    HSplitView {
                        contentWithHeaderAndFooter
                            .frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
                            .appSplitDivider(
                                .trailing,
                                initialPosition: trailingPane.idealWidth,
                                onResize: trailingPane.saveWidth
                            )
                        trailingPane.content
                            .frame(
                                minWidth: trailingPane.minWidth,
                                idealWidth: trailingPane.idealWidth,
                                maxWidth: trailingPane.maxWidth,
                                maxHeight: .infinity
                            )
                    }
                    #else
                    HStack(spacing: 0) {
                        contentWithHeaderAndFooter
                        Divider()
                        trailingPane.content
                            .frame(
                                minWidth: trailingPane.minWidth,
                                idealWidth: trailingPane.idealWidth,
                                maxWidth: trailingPane.maxWidth
                            )
                    }
                    #endif
                } else {
                    // 无主内容：trailing pane 独占，不渲染占位视图。
                    trailingPane.content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                contentWithHeaderAndFooter
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
