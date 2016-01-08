//
//  PagerContainerView.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit

public class PagerContainerView: UIView {
    
    // MARK: - Public Handler Properties
    
    public var didShowViewControllerHandler : (UIViewController -> Void)?
    
    public var startSyncHandler : (Int -> Void)?
    
    public var syncOffsetHandler : ((currentIndex: Int, percentComplete: CGFloat, scrollingTowards: Bool) -> Void)?
    
    public var finishSyncHandler : (Int -> Void)?
    
    // MARK: - Private Properties
    
    private lazy var scrollView : InfiniteScrollView = {
        var scrollView = InfiniteScrollView(frame: self.bounds)
        scrollView.infiniteDataSource = self
        scrollView.infiniteDelegate = self
        scrollView.backgroundColor = UIColor.clearColor()
        return scrollView
    }()
    
    private var viewControllers : [UIViewController] = []
    
    private var identifiers : [String] = []
    
    private var startDraggingOffsetX : CGFloat?
    
    private var startDraggingIndex : Int?
    
    // MARK: - Constructor
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.addSubview(self.scrollView)
        self.scrollView.pagingEnabled = true
        self.scrollView.scrollsToTop = false
        
        self.setupConstraint()
    }
    
    // MARK: - Override
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.frame = self.bounds
    }
    
    // MARK: - Public Functions
    
    public func addViewController(identifier: String, viewController: UIViewController) {
        self.identifiers.append(identifier)
        self.viewControllers.append(viewController)
        self.scrollView.reloadViews()
    }
    
    public func scrollToCenter(index: Int, animated: Bool, animation: (Void -> Void)?, completion: (Void -> Void)?) {
        if !self.scrollView.dragging {
            let _index = self.currentIndex()
            if _index == index { return }
            if _index > index {
                self.scrollView.resetWithIndex(index + 1)
            } else {
                self.scrollView.resetWithIndex(index - 1)
            }
            self.scrollView.scrollToCenter(index, animated: animated, animation: animation, completion: completion)
        }
    }
    
    public func currentIndex() -> Int {
        if let _currentItem = self.scrollView.itemAtCenterPosition() {
            return _currentItem.index
        }
        return Int.min
    }
}

// MARK: - Layout

extension PagerContainerView {
    
    private func setupConstraint() {
        self.allPin(self.scrollView)
    }
}

// MARK: - Sync ContainerView Scrolling

extension PagerContainerView {
    
    private func finishSyncViewScroll(index: Int) {
        self.finishSyncHandler?(index)
        self.startDraggingOffsetX = nil
        self.scrollView.setNeedsLayout()
        self.scrollView.layoutIfNeeded()
    }
}

// MARK: - InfiniteScrollViewDataSource

extension PagerContainerView: InfiniteScrollViewDataSource {
    
    public func totalItemCount() -> Int {
        return self.identifiers.count
    }
    
    public func identifierForIndex(index: Int) -> String {
        let identifier = self.identifiers[index]
        
        return identifier
    }
    
    public func viewForIndex(index: Int) -> UIView {
        let controller = self.viewControllers[index]
        
        return controller.view
    }
    
    public func thicknessForIndex(index: Int) -> CGFloat {
        return self.frame.size.width
    }
}

// MARK: - InfiniteScrollViewDelegate

extension PagerContainerView: InfiniteScrollViewDelegate {
    
    public func updateContentOffset(delta: CGFloat) {
        self.startDraggingOffsetX? += delta
    }
    
    public func infiniteScrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        
    }
    
    public func infiniteScrollViewWillBeginDragging(scrollView: UIScrollView) {
        if let _currentItem = self.scrollView.itemAtCenterPosition() {
            if self.startDraggingOffsetX == nil {
                self.startSyncHandler?(_currentItem.index)
            } else {
                self.finishSyncViewScroll(_currentItem.index)
            }
        }
    }
    
    public func infinitScrollViewDidScroll(scrollView: UIScrollView) {
        if let _startDraggingOffsetX = self.startDraggingOffsetX {
            let width = CGRectGetWidth(scrollView.bounds)
            let offsetX = scrollView.contentOffset.x
            let scrollingTowards = _startDraggingOffsetX > offsetX
            let percent = (offsetX - _startDraggingOffsetX) / width
            let percentComplete = scrollingTowards == false ? percent : (1 - percent) - 1
            let _percentComplete = percentComplete * 1.1
            
            if let _currentItem = self.scrollView.itemAtCenterPosition() {
                self.syncOffsetHandler?(currentIndex: _currentItem.index, percentComplete: _percentComplete, scrollingTowards: scrollingTowards)
            }
        } else {
            if scrollView.dragging {
                self.startDraggingOffsetX = scrollView.contentOffset.x
            }
        }
    }
    
    public func infiniteScrollViewDidEndCenterScrolling(item: InfiniteItem) {
        let controller = self.viewControllers.filter(){ controller in return controller.view == item.view }.first!
        self.didShowViewControllerHandler?(controller)
        
        guard self.startDraggingOffsetX != nil else { return }
        
        if let _currentItem = self.scrollView.itemAtCenterPosition() {
            self.scrollView.scrollToCenter(_currentItem.index, animated: false, animation: nil, completion: nil)
            self.finishSyncViewScroll(_currentItem.index)
        }
    }
    
    public func infiniteScrollViewDidShowCenterItem(item: InfiniteItem) {
        let controller = self.viewControllers.filter(){ controller in return controller.view == item.view }.first!
        self.didShowViewControllerHandler?(controller)
    }
}