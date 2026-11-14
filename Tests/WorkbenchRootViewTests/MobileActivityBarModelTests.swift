import ProviderActivityBar
import Testing
@testable import WorkbenchRootView

/// 移动端底部标签栏的排序与显隐规则。
@Suite("MobileActivityBarModel")
@MainActor
struct MobileActivityBarModelTests {
    private func item(_ id: String, order: Int) -> ActivityBarItem {
        ActivityBarItem(id: id, title: id, systemImage: "circle", order: order)
    }

    @Test("入口按 order 升序排列")
    func itemsAreSortedByOrder() {
        let model = MobileActivityBarModel(
            items: [item("c", order: 30), item("a", order: 10), item("b", order: 20)],
            activeItemID: nil,
            isVisible: true
        )

        #expect(model.items.map(\.id) == ["a", "b", "c"])
    }

    @Test("至少两个入口才显示标签栏")
    func barRequiresAtLeastTwoItems() {
        let single = MobileActivityBarModel(
            items: [item("a", order: 0)],
            activeItemID: "a",
            isVisible: true
        )
        #expect(single.shouldShowBar == false)

        let pair = MobileActivityBarModel(
            items: [item("a", order: 0), item("b", order: 1)],
            activeItemID: "a",
            isVisible: true
        )
        #expect(pair.shouldShowBar)
    }

    @Test("provider 禁止显示时不显示标签栏")
    func providerVisibilityWins() {
        let model = MobileActivityBarModel(
            items: [item("a", order: 0), item("b", order: 1)],
            activeItemID: "a",
            isVisible: false
        )
        #expect(model.shouldShowBar == false)
    }
}
