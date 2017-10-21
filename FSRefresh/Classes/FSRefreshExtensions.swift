
import UIKit

// MARK: - NSObject Extension

public extension NSObject {
    
    // MARK: - Vars
    
    fileprivate struct fsrefresh_associatedKeys {
        static var observersArray = "observers"
    }
    
    fileprivate var fsrefresh_observers: [[String : NSObject]] {
        get {
            if let observers = objc_getAssociatedObject(self, &fsrefresh_associatedKeys.observersArray) as? [[String : NSObject]] {
                return observers
            } else {
                let observers = [[String : NSObject]]()
                self.fsrefresh_observers = observers
                return observers
            }
        } set {
            objc_setAssociatedObject(self, &fsrefresh_associatedKeys.observersArray, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Methods
    
    public func fsrefresh_addObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        
        let observerInfo = [keyPath : observer]
        
        if fsrefresh_observers.index(where: { $0 == observerInfo }) == nil {
            fsrefresh_observers.append(observerInfo)
            addObserver(observer, forKeyPath: keyPath, options: .new, context: nil)
        }
    }
    
    public func fsrefresh_removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        
        let observerInfo = [keyPath : observer]
        
        if let index = fsrefresh_observers.index(where: { $0 == observerInfo}) {
            fsrefresh_observers.remove(at: index)
            removeObserver(observer, forKeyPath: keyPath)
        }
    }
    
}


// MARK: - UIScrollView Header Refresh Extension

public extension UIScrollView {
    
    // MARK: - Vars
    public var fs_isHeaderRefreshing: Bool {
        if _refreshHeaderView == nil {
            return false
        }
        return refreshHeaderView.state == .refreshing
    }
    
    fileprivate struct fsrefresh_associatedKeys {
        static var FSRefreshHeaderViewKey = "FSRefreshHeaderViewKey"
        static var FSRefreshFooterViewKey = "FSRefreshFooterViewKey"
    }
    
    private var _refreshHeaderView: FSRefreshHeaderView? {
        get {
            if let refreshHeaderView = objc_getAssociatedObject(self, &fsrefresh_associatedKeys.FSRefreshHeaderViewKey) as? FSRefreshHeaderView {
                return refreshHeaderView
            }
            
            return nil
        }
        set {
            objc_setAssociatedObject(self, &fsrefresh_associatedKeys.FSRefreshHeaderViewKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var refreshHeaderView: FSRefreshHeaderView! {
        get {
            if let refreshHeaderView = _refreshHeaderView {
                return refreshHeaderView
            } else {
                let refreshHeaderView = FSRefreshHeaderView()
                _refreshHeaderView = refreshHeaderView
                return refreshHeaderView
            }
        }
    }
    
    /// 添加头部刷新. (默认以 contentInset 作为刷新控件的顶部偏移量)
    public func fs_addHeaderRefresh(_ actionHandler: FSRefreshHandler?) {
        fs_addHeaderRefresh(topEdge: contentInset.top, actionHandler)
    }
    
    /// 添加头部刷新, 并设置刷新控件的顶部偏移量.
    public func fs_addHeaderRefresh(topEdge: CGFloat, _ actionHandler: FSRefreshHandler?) {
        if _refreshHeaderView != nil {
            fs_removeHeaderRefresh()
        }
        
        alwaysBounceVertical = true
        
        refreshHeaderView.topEdge = topEdge
        refreshHeaderView.actionHandler = actionHandler
        refreshHeaderView.backgroundColor = backgroundColor
        addSubview(refreshHeaderView)
        refreshHeaderView.observing = true
    }
    
    public func fs_setRefreshHeaderViewBackgroundColor(_ color: UIColor) {
        guard _refreshHeaderView != nil else {
            return
        }
        refreshHeaderView.backgroundColor = color
    }
    
    public func fs_startHeaderRefresh() {
        guard _refreshHeaderView != nil else {
            return
        }
        refreshHeaderView.startRefreshing()
    }
    
    public func fs_stopHeaderRefresh(success: Bool) {
        guard _refreshHeaderView != nil else {
            return
        }
        refreshHeaderView.stopRefreshing(success: success)
    }
    
    public func fs_removeHeaderRefresh() {
        guard _refreshHeaderView != nil else {
            return
        }
        refreshHeaderView.observing = false
        refreshHeaderView.removeFromSuperview()
        _refreshHeaderView = nil
    }
}


// MARK: - UIScrollView Footer Refresh Extension

public extension UIScrollView {
    
    // MARK: - Vars
    public var fs_isFootRefreshing: Bool {
        if _refreshFooterView == nil {
            return false
        }
        return refreshFooterView.state == .refreshing
    }
    
    private var _refreshFooterView: FSRefreshFooterView? {
        get {
            if let refreshFooterView = objc_getAssociatedObject(self, &fsrefresh_associatedKeys.FSRefreshFooterViewKey) as? FSRefreshFooterView {
                return refreshFooterView
            }
            
            return nil
        }
        set {
            objc_setAssociatedObject(self, &fsrefresh_associatedKeys.FSRefreshFooterViewKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var refreshFooterView: FSRefreshFooterView! {
        get {
            if let refreshFooterView = _refreshFooterView {
                return refreshFooterView
            } else {
                let refreshFooterView = FSRefreshFooterView()
                _refreshFooterView = refreshFooterView
                return refreshFooterView
            }
        }
    }
    
    /// 添加尾部刷新, 该函数设置的尾部刷新为自动刷新.
    public func fs_addFooterRefresh(_ actionHandler: FSRefreshHandler?) {
        fs_addFooterRefresh(isAutoRefresh: true, actionHandler)
    }
    
    /// 添加尾部刷新.
    public func fs_addFooterRefresh(isAutoRefresh: Bool, _ actionHandler: FSRefreshHandler?) {
        
        if _refreshFooterView != nil {
            fs_removeHeaderRefresh()
        }
        
        alwaysBounceVertical = true
        
        refreshFooterView.actionHandler = actionHandler
        refreshFooterView.isAutoRefresh = isAutoRefresh
        refreshFooterView.backgroundColor = backgroundColor
        addSubview(refreshFooterView)
        refreshFooterView.observing = true
    }
    
    public func fs_setRefreshFooterViewBackgroundColor(_ color: UIColor) {
        guard _refreshFooterView != nil else {
            return
        }
        refreshFooterView.backgroundColor = color
    }
    
    public func fs_startFooterRefresh() {
        guard _refreshFooterView != nil else {
            return
        }
        refreshFooterView.startRefreshing()
    }
    
    /// 停止刷新
    /// isEmpty: 是否是已经全部加载, 如果为 true 则不再能上拉刷新, 如果为 false 则允许重新上拉加载.
    public func fs_stopFooterRefresh(isNoMoreData: Bool) {
        guard _refreshFooterView != nil else {
            return
        }
        refreshFooterView.stopRefreshing(isNoMoreData: isNoMoreData)
    }
    
    public func fs_removeFooterRefresh() {
        guard _refreshFooterView != nil else {
            return
        }
        refreshFooterView.observing = false
        refreshFooterView.removeFromSuperview()
        _refreshFooterView = nil
    }
}
