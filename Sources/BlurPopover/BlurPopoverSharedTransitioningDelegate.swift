//
//  BlurPopoverSharedTransitioningDelegate.swift
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

open class BlurPopoverSharedTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private let presentingSourceView: UIView?
    private let dismissingDestinationView: UIView?
    init(presentingSourceView: UIView? = nil, dismissingDestinationView: UIView? = nil) {
        self.presentingSourceView = presentingSourceView
        self.dismissingDestinationView = dismissingDestinationView
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        BlurPopoverPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let sourceView = presentingSourceView else { return nil }
        return BlurPopoverAnimationController(isPresenting: true, sourceView: sourceView)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        defer { Self.shared.removeAll(where: { $0 == self }) }
        guard let sourceView = dismissingDestinationView else { return nil }
        return BlurPopoverAnimationController(isPresenting: false, sourceView: sourceView)
    }
    
    public static var shared = [BlurPopoverSharedTransitioningDelegate]()
    public static func sharedDelegate(presentingSourceView: UIView? = nil, dismissingDestinationView: UIView? = nil) -> BlurPopoverSharedTransitioningDelegate? {
        let controller = BlurPopoverSharedTransitioningDelegate(
            presentingSourceView: presentingSourceView,
            dismissingDestinationView: dismissingDestinationView
        )
        Self.shared.append(controller)
        return controller
    }
}
