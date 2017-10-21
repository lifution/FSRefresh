
import UIKit

class FSRefreshHeaderView: UIView {
    
    // MARK: - Vars
    
    var actionHandler: FSRefreshHandler?
    
    var observing: Bool = false {
        didSet {
            guard let scrollView = scrollView() else { return }
            if observing {
                scrollView.fsrefresh_addObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentOffset)
                scrollView.fsrefresh_addObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentInset)
            } else {
                scrollView.fsrefresh_removeObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentOffset)
                scrollView.fsrefresh_removeObserver(self, forKeyPath: FSRefreshConstants.KeyPaths.ContentInset)
            }
        }
    }
    
    var refreshSuccessText: String? {
        set {
            resultStateView.setTitle(refreshSuccessText, for: .normal)
            resultStateView.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 2.5)
            resultStateView.titleEdgeInsets = UIEdgeInsetsMake(0, 2.5, 0, -2.5)
        }
        get {
            return resultStateView.title(for: .normal)
        }
    }
    var refreshFailText: String? {
        set {
            resultStateView.setTitle(refreshFailText, for: .selected)
            resultStateView.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 2.5)
            resultStateView.titleEdgeInsets = UIEdgeInsetsMake(0, 2.5, 0, -2.5)
        }
        get {
            return resultStateView.title(for: .selected)
        }
    }
    
    /// 顶部偏移
    var topEdge: CGFloat = 0.0
    
    private(set) var state: FSRefreshState = .stopped
    
    private var topConstraint: NSLayoutConstraint?
    
    private var refreshSuccess: Bool {
        set {
            resultStateView.isSelected = !newValue
        }
        get {
            return !resultStateView.isSelected
        }
    }
    
    private lazy var resultStateView: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.isUserInteractionEnabled = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor(red:0.60, green:0.60, blue:0.60, alpha:1.00), for: .normal)
        button.setTitleColor(UIColor(red:0.96, green:0.31, blue:0.13, alpha:1.00), for: .selected)
        button.setTitle("加载成功", for: .normal)
        button.setTitle("加载失败", for: .selected)
        if let successImagePath = Bundle(for: FSRefreshHeaderView.self).path(forResource: "fsrefresh_success@2x", ofType: "png") {
            button.setImage(UIImage(contentsOfFile: successImagePath), for: .normal)
        }
        if let failImagePath = Bundle(for: FSRefreshHeaderView.self).path(forResource: "fsrefresh_fail@2x", ofType: "png") {
            button.setImage(UIImage(contentsOfFile: failImagePath), for: .selected)
        }
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 2.5)
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 2.5, 0, -2.5)
        
        return button
    }()
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        return indicatorView
    }()
    
    private lazy var arrowView: UIImageView = {
        let imageView =  UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        if let imagePath = Bundle(for: FSRefreshHeaderView.self).path(forResource: "fsrefresh_arrow@2x", ofType: "png") {
            imageView.image = UIImage(contentsOfFile: imagePath)
        }
        
        return imageView
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
            topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: -(FSRefreshConstants.HeaderHeight + view.contentInset.top) + topEdge)
            view.addConstraint(topConstraint!)
            view.addConstraint(NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0))
            view.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0.0))
            view.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: FSRefreshConstants.HeaderHeight))
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
        if keyPath == FSRefreshConstants.KeyPaths.ContentInset {
            if state == .refreshing || state == .endingRefreshing {
                return
            }
            if let newInset = (newChange as AnyObject).uiEdgeInsetsValue {
                topConstraint?.constant = -(FSRefreshConstants.HeaderHeight + newInset.top) + topEdge
            }
        }
        
        // contentOffset
        if keyPath == FSRefreshConstants.KeyPaths.ContentOffset {
            
            // 正在刷新 / 正在停止刷新, 直接返回.
            if state == .refreshing || state == .endingRefreshing {
                return
            }
            
            guard let scrollView = scrollView() else {
                return
            }
            
            if scrollView.isHidden || scrollView.alpha <= 0.01 {
                return
            }
            
            let newContentOffsetY = (newChange as AnyObject).cgPointValue.y
            
            // 如果是向上滚动到看不见头部控件，直接返回.
            if newContentOffsetY >= -scrollView.contentInset.top {
                return
            }
            
            let relativeOffsetY: CGFloat = CGFloat(fabs(Double(newContentOffsetY)) - fabs(Double(scrollView.contentInset.top)))
            
            if scrollView.isDragging {
                if relativeOffsetY < FSRefreshConstants.HeaderMinOffsetToRefresh {
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
        frame = CGRect(x: 0, y: 0, width: 0, height: FSRefreshConstants.HeaderHeight)
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        
        // refresh result state
        addSubview(resultStateView)
        addConstraint(NSLayoutConstraint(item: resultStateView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: resultStateView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        
        // indicator
        addSubview(indicatorView)
        addConstraint(NSLayoutConstraint(item: indicatorView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: indicatorView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        
        // arrow
        addSubview(arrowView)
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
    /// 所依附的 UIScrollView.
    private func scrollView() -> UIScrollView? {
        return superview as? UIScrollView
    }
    
    // MARK: Functions (Public)
    
    /// 开始刷新
    func startRefreshing() {
        if state == .refreshing {
            return
        }
        if let scrollView = scrollView() {
            
            if state == .endingRefreshing {
                scrollView.contentInset.top -= FSRefreshConstants.HeaderMinOffsetToRefresh
            }
            
            actionHandler?()
            state = .refreshing
            arrowView.isHidden = true
            arrowView.transform = CGAffineTransform.identity
            resultStateView.isHidden = true
            indicatorView.startAnimating()
            UIView.animate(withDuration: FSRefreshConstants.AnimationDuration, animations: {
                scrollView.contentInset.top += FSRefreshConstants.HeaderMinOffsetToRefresh
                scrollView.contentOffset = CGPoint(x: 0, y: -scrollView.contentInset.top)
            })
        }
    }
    
    /// 停止刷新
    func stopRefreshing(success: Bool) {
        if let scrollView = scrollView(), state == .refreshing {
            indicatorView.stopAnimating()
            state = .endingRefreshing
            refreshSuccess = success
            resultStateView.alpha = 0.0
            resultStateView.isHidden = false
            UIView.animate(withDuration: 0.15, animations: {
                self.resultStateView.alpha = 1.0
            }, completion: { (finish) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    if self.state == .refreshing {
                        return
                    }
                    UIView.animate(withDuration: FSRefreshConstants.AnimationDuration, animations: {
                        scrollView.contentInset.top -= FSRefreshConstants.HeaderMinOffsetToRefresh
                    }, completion: { (finished) in
                        self.state = .stopped
                        self.arrowView.isHidden = false
                        self.resultStateView.isHidden = true
                    })
                })
            })
        }
    }
}
