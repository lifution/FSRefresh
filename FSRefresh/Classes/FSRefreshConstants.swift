
import UIKit

public typealias FSRefreshHandler = () -> Void

public struct FSRefreshConstants {
    struct KeyPaths {
        static let ContentInset = "contentInset"
        static let ContentOffset = "contentOffset"
        static let ContentSize = "contentSize"
    }
    
    static let AnimationDuration: TimeInterval = 0.25
    static let HeaderHeight: CGFloat = 50.0
    static let HeaderMinOffsetToRefresh: CGFloat = HeaderHeight
    static let FooterHeight: CGFloat = 50.0
    static let FooterMinOffsetToRefresh: CGFloat = FooterHeight
    static let FooterAutoMinOffset: CGFloat = 50.0
}

public enum FSRefreshState: Int {
    case stopped            // 停止状态
    case dragging           // 正在滑动, 但是还没到达可以刷新的位置
    case refreshing         // 正在刷新
    case canRefreshing      // 正在滑动, 已经到达可以刷新的位置
    case endingRefreshing   // 正在停止刷新的过程中
    case noMoreData         // 没有更多数据 (该状态一般用于尾部刷新)
}
