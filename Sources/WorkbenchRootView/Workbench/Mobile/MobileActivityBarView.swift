import LumiUI
import ProviderActivityBar
import SwiftUI

/// 移动端底部标签栏的纯数据模型。
///
/// 把排序与显隐规则从视图里拆出来，便于脱离 SwiftUI 视图树直接单测。
@MainActor
public struct MobileActivityBarModel {
    /// 按 `order` 升序排列的入口。
    public let items: [ActivityBarItem]

    /// 当前激活入口。
    public let activeItemID: String?

    /// provider 是否允许显示入口栏。
    public let isVisible: Bool

    public init(items: [ActivityBarItem], activeItemID: String?, isVisible: Bool) {
        self.items = items.sorted { $0.order < $1.order }
        self.activeItemID = activeItemID
        self.isVisible = isVisible
    }

    /// 至少两个入口时才显示底部标签栏：单个入口下标签栏没有可切换的对象。
    public var shouldShowBar: Bool {
        isVisible && items.count > 1
    }
}

/// 移动端底部标签栏：ActivityBar 的条目在 iOS 上呈现为底部 tab。
@MainActor
struct MobileActivityBarView: View {
    let model: MobileActivityBarModel
    let onSelect: @MainActor (String) -> Void
    @LumiTheme private var theme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(model.items) { item in
                tab(item)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(theme.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.divider)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func tab(_ item: ActivityBarItem) -> some View {
        let isActive = item.id == model.activeItemID
        Button {
            onSelect(item.id)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                    .frame(height: 24)
                Text(item.title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isActive ? theme.primary : theme.textSecondary)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("workbench.activity.\(item.id)")
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
