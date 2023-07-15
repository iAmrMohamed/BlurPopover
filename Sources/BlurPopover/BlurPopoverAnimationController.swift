//
//  BlurPopoverAnimationController.swift
//
//  Copyright (c) 2020 Amr Mohamed (https://github.com/iAmrMohamed)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

open class BlurPopoverAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let sourceView: UIView
    
    private var centerPoint: CGPoint {
        sourceView.superview?.convert(sourceView.center, to: nil) ?? .zero
    }
    
    public init(isPresenting: Bool, sourceView: UIView) {
        self.isPresenting = isPresenting
        self.sourceView = sourceView
    }
    
    public func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        isPresenting ? 0.5 : 0.33
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }
    
    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let snapShotView = sourceView.snapshotView(afterScreenUpdates: true) else { return }
        
        containerView.addSubview(toVC.view)
        
        let toVCFrame = toVC.presentationController?.frameOfPresentedViewInContainerView ?? toVC.view.frame
        
        let heightScale = sourceView.bounds.height / toVCFrame.height
        let widthScale = sourceView.bounds.width / toVCFrame.width
        
        toVC.view.center = centerPoint
        toVC.view.transform = .init(scaleX: widthScale, y: heightScale)
        
        snapShotView.center = centerPoint
        containerView.insertSubview(snapShotView, at: 0)
        
        let snapShotTargetScale = toVCFrame.width / sourceView.bounds.width
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
            toVC.view.alpha = 1.0
            toVC.view.transform = .identity
            toVC.view.center = .init(x: toVCFrame.midX, y: toVCFrame.midY)
            
            snapShotView.alpha = 0
            snapShotView.center = containerView.center
            snapShotView.transform = .init(scaleX: snapShotTargetScale, y: snapShotTargetScale)
        }) { _ in
            snapShotView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let snapShotView = sourceView.snapshotView(afterScreenUpdates: true) else { return }
        
        let fromVCFrame = fromVC.view.frame
        
        
        containerView.insertSubview(snapShotView, belowSubview: fromVC.view)
        
        snapShotView.center = .init(
            x: fromVCFrame.origin.x + (fromVCFrame.width / 2),
            y: fromVCFrame.origin.y + (fromVCFrame.height / 2)
        )
        
        let snapShotTargetScale = fromVCFrame.width / sourceView.bounds.width
        snapShotView.transform = .init(scaleX: snapShotTargetScale, y: snapShotTargetScale)
        
        let heightScale = sourceView.frame.height / fromVCFrame.height
        let widthScale = sourceView.bounds.width / fromVCFrame.width
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            fromVC.view.alpha = 0
            fromVC.view.transform = .init(scaleX: widthScale, y: heightScale)
            fromVC.view.center = self.centerPoint
            
            snapShotView.alpha = 1
            snapShotView.center = self.centerPoint
            snapShotView.transform = .identity
        }) { flag in
            snapShotView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
