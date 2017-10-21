
import UIKit

class FSRefreshFooterView: UIView {
    
    // MARK: - Vars
    
    public var actionHandler: FSRefreshHandler?
    
    public var observing: Bool = false {
        didSet {
            guard let scrollView = scrollView() else { return }
            if observing {
                scrollView.fsrefresh_addObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentSize)
                scrollView.fsrefresh_addObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentOffset)
//                scrollView.fsrefresh_addObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentInset)
            } else {
                scrollView.fsrefresh_addObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentSize)
                scrollView.fsrefresh_removeObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentOffset)
//                scrollView.fsrefresh_removeObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentInset)
            }
        }
    }
    
    public var isAutoRefresh = false
    
    private(set) var state: FSRefreshState = .stopped
    
    private var topConstraint: NSLayoutConstraint?
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        return indicatorView
    }()
    
    private lazy var arrowView: UIImageView = {
        let imageView =  UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        if let imagePath = Bundle(for: FSRefreshFooterView.self).path(forResource: "fsrefresh_arrow@2x", ofType: "png") {
            
            let image = UIImage(contentsOfFile: imagePath)
            if let cgImage = image?.cgImage {
                
                imageView.image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .down)
            } else {
                
                imageView.image = image
            }
        }
        
        return imageView
    }()
    
    /// 没有更多数据的提示label
    private lazy var noticeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.text = "到底了。--所以往后的每一步都在上升"
        label.isHidden = true
        label.textColor = UIColor(red:0.56, green:0.56, blue:0.56, alpha:1.00)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // MARK: - Constructors
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    deinit {
        observing = false
    }
    
    // MARK: - Functions (Override)
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let view = superview as? UIScrollView {
            
            view.layoutIfNeeded()
            let topConstant = max(view.contentSize.height, view.bounds.height - view.contentInset.top - view.contentInset.bottom)
            topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: topConstant)
            view.addConstraint(topConstraint!)
            view.addConstraint(NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0))
            view.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0.0))
            view.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: FSRefreshConstants.FooterHeight))
        }
    }
    
    override func removeFromSuperview() {
        observing = false
        super.removeFromSuperview()
    }
    
    // kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let newChange = change?[NSKeyValueChangeKey.newKey] else {
            return
        }
        
        // contentInset
        //        if keyPath == FSRefreshConstants.KeyPaths.ContentInset {
        //            if state == .refreshing || state == .endingRefreshing {
        //                return
        //            }
        //            if let newInset = (newChange as AnyObject).uiEdgeInsetsValue {
        //                frame.origin.y = -(frame.height + newInset.top)
        //            }
        //        }
        
        // contentSize
        if keyPath == FSRefreshConstants.KeyPaths.ContentSize {
            
            guard let scrollView = scrollView() else {
                return
            }
            
            // 更新刷新控件的位置.
            topConstraint?.constant = max(scrollView.contentSize.height, scrollView.bounds.height - scrollView.contentInset.top)
        }
        
        // contentOffset
        if keyPath == FSRefreshConstants.KeyPaths.ContentOffset {
            
            // 正在刷新 / 正在停止刷新 / 全部加载完成, 直接返回.
            if state == .refreshing || state == .endingRefreshing || state == .noMoreData {
                return
            }
            
            guard let scrollView = scrollView() else {
                return
            }
            
            if scrollView.isHidden || scrollView.alpha <= 0.01 || scrollView.bounds.size == CGSize.zero {
                return
            }
            
            let newContentOffsetY = (newChange as AnyObject).cgPointValue.y
            
            topConstraint?.constant = max(scrollView.contentSize.height, scrollView.bounds.height - scrollView.contentInset.top)
            
            /// 抽象的尾部刷新控件的可视 `y轴` 坐标 (以scrollView的底部为原点, 正方向为垂直向上).
            let footerVisibleY = -(topConstraint!.constant - scrollView.bounds.height - newContentOffsetY)
            
            // 自动刷新.
            // 必须是进入了自动刷新的范围, 并且是允许自动刷新, 而且还要满足 contentSize 的高度比当前 scrollView 的可视高度还高, 满足这三个条件才自动刷新, 否则需要用户手动上拉刷新.
            if footerVisibleY >= -FSRefreshConstants.FooterAutoMinOffset && isAutoRefresh && (scrollView.contentSize.height - (scrollView.bounds.height - scrollView.contentInset.top) > 0) {
                
                let yVelocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y
                if yVelocity > 0 { // 如果进入自动刷新的范围并且是向下滑动的话则不自动刷新.
                    return
                }
                startRefreshing()
                return
            }
            
            // 如果是向下滚动到看不见尾部控件，直接返回.
            if footerVisibleY < 0.0 {
                return
            }
            
            if scrollView.isDragging {
                if footerVisibleY < FSRefreshConstants.HeaderMinOffsetToRefresh {
                    state = .dragging
                } else {
                    state = .canRefreshing
                }
                
                if state == .canRefreshing {
                    UIView.animate(withDuration: FSRefreshConstants.AnimationDuration, animations: {
                        self.arrowView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                    })
                }
                if state == .dragging {
                    UIView.animate(withDuration: FSRefreshConstants.AnimationDuration, animations: {
                        self.arrowView.transform = CGAffineTransform.identity
                    })
                }
            } else {
                if state == .canRefreshing {
                    startRefreshing()
                }
            }
        }
    }
    
    // MARK: - Functions (Private)
    
    /// Common init
    private func commonInit() {
        frame = CGRect(x: 0, y: 0, width: 0, height: FSRefreshConstants.FooterHeight)
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        
        // indicator
        addSubview(indicatorView)
        addConstraint(NSLayoutConstraint(item: indicatorView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: indicatorView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        
        // arrow
        addSubview(arrowView)
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        
        // notice
        addSubview(noticeLabel)
        addConstraint(NSLayoutConstraint(item: noticeLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: noticeLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: noticeLabel, attribute: .left, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .left, multiplier: 1.0, constant: 10.0))
        addConstraint(NSLayoutConstraint(item: noticeLabel, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .right, multiplier: 1.0, constant: -10.0))
    }
    
    /// 所依附的 UIScrollView.
    private func scrollView() -> UIScrollView? {
        return superview as? UIScrollView
    }
    
    /// 底部空白区高度. (contentSize不能全部填充bounds.size的时候)
    private func bottomEmptyHeight() -> CGFloat {
        guard let scrollView = scrollView() else {
            return 0.0
        }
        let height = scrollView.bounds.height - scrollView.contentInset.top - scrollView.contentSize.height
        return max(height, 0.0)
    }
    
    // MARK: Functions (Public)
    
    /// 开始刷新
    func startRefreshing() {
        if state == .refreshing {
            return
        }
        
        guard let scrollView = scrollView() else {
            return
        }
        
        state = .refreshing
        arrowView.isHidden = true
        arrowView.transform = CGAffineTransform.identity
        indicatorView.startAnimating()
        UIView.animate(withDuration: FSRefreshConstants.AnimationDuration, animations: {
            
            // 底部空白区比刷新控件高度还大则将刷新控件添加到scrollView的底部.
            let emptyHeight = self.bottomEmptyHeight()
            if emptyHeight >= FSRefreshConstants.FooterMinOffsetToRefresh {
                self.topConstraint?.constant = scrollView.bounds.height - scrollView.contentInset.top - FSRefreshConstants.FooterHeight
            } else {
                scrollView.contentInset.bottom += FSRefreshConstants.FooterMinOffsetToRefresh + emptyHeight
                scrollView.contentOffset.y = max(scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom, 0)
            }
        }, completion: { (finished) in
            if self.state == .refreshing {
                self.actionHandler?()
            }
        })
    }
    
    /// 停止刷新
    /// isNoMoreData: 是否是已经全部加载, 如果为 true 则不再能上拉刷新, 如果为 false 则允许重新上拉加载.
    func stopRefreshing(isNoMoreData: Bool) {
        
        guard let scrollView = scrollView(), (state == .refreshing || state == .noMoreData) else {
            return
        }
        
        indicatorView.stopAnimating()
        
        // 已全部加载
        if isNoMoreData {
            state = .noMoreData
            noticeLabel.isHidden = false
            topConstraint?.constant = scrollView.contentSize.height
            // 保证能至少看到底部的提示信息.
            let emptyHeight = bottomEmptyHeight()
            if emptyHeight < FSRefreshConstants.FooterHeight {
                scrollView.contentInset.bottom -= emptyHeight
            }
            return
        }
        
        state = .endingRefreshing
        
        UIView.animate(withDuration: FSRefreshConstants.AnimationDuration, animations: {
            // 底部空白区比刷新控件高度还大则恢复刷新控件添加到scrollView的底部.
            let emptyHeight = self.bottomEmptyHeight()
            if emptyHeight >= FSRefreshConstants.FooterHeight {
                self.topConstraint?.constant = scrollView.bounds.height - scrollView.contentInset.top
            } else {
                scrollView.contentInset.bottom -= FSRefreshConstants.FooterMinOffsetToRefresh + emptyHeight
            }
        }, completion: { (finished) in
            if self.state == .endingRefreshing {
                self.state = .stopped
                self.arrowView.isHidden = false
                self.noticeLabel.isHidden = true
            }
        })
    }
}
