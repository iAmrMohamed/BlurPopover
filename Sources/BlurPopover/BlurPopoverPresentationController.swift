//
//  BlurPopoverPresentationController.swift
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

open class BlurPopoverPresentationController: UIPresentationController {
    private struct Constants {
        static let scaleLimit = CGFloat(0.75)
        static let dismissVelocityLimit = CGFloat(1000)
        static let dismissButtonHeight = CGFloat(30)
        static let topStackViewHeight = CGFloat(30)
    }
    
    private lazy var topStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 10
        view.axis = .horizontal
        view.distribution = .equalSpacing
        view.heightAnchor.constraint(equalToConstant: Constants.topStackViewHeight).isActive = true
        return view
    }()
        
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .close)
        button.backgroundColor = .systemBackground
        button.tintColor = UIColor.gray
        button.layer.cornerRadius = Constants.dismissButtonHeight / 2
        button.addTarget(self, action: #selector(self.dismissPresentedVC), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: Constants.dismissButtonHeight).isActive = true
        button.widthAnchor.constraint(equalToConstant: Constants.dismissButtonHeight).isActive = true
        return button
    }()
    
    /// The background blurring view
    private lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(self.dismissPresentedVC))
        )
        return view
    }()
    
    private var blurEffect: UIBlurEffect {
        UIBlurEffect(style: .dark)
    }
    
    /// The animator responsible for changing the radius of blurView
    private lazy var blurAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
        self.blurView.effect = self.blurEffect
    }
    
    // MARK: - Publics
    
    /// The popover insets,  defaults to (top: 20, left: 20, bottom: 50, right: 20)
    public lazy var popoverInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    
    private var keyboardPopoverInsets: UIEdgeInsets {
        var inset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        if let containerView = self.containerView { inset.bottom -= containerView.safeAreaInsets.bottom }
        inset.top += Constants.topStackViewHeight
        return inset
    }
    
    /// This controls the blur radius of the blurView, The value should be from 0.0 to 1.0, defaults to 0.25
    public var blurFractionComplete = CGFloat(0.25)
    
    // MARK: - Privates
    
    private var titleObserver: NSKeyValueObservation?
    
    private var isKeyboardVisible = false
    private var keyboardHeight = CGFloat()
    
    /// The first tableView or a collectionView that was detected in the presentedView subviews
    public var trackingScrollView: UIScrollView?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        registerKeyboardObservers()
        registerApplicationNotificationsObservers()
    }
    
    open override func presentationTransitionWillBegin() {
        setupPresentedView()
        setupBlurView()
        setupTopStackView()
        
        presentedViewController.view.alpha = 0
        presentedViewController.preferredContentSize = containerView?.bounds.size ?? .zero
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.alpha = 1
            self.presentedViewController.view.alpha = 1
            self.containerView?.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        })
    }
    
    open override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.removeFromSuperview()
            self.topStackView.removeFromSuperview()
            self.containerView?.backgroundColor = .clear
        }, completion: { _ in
            self.blurAnimator.stopAnimation(true)
        })
    }
    
    open override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = self.containerView else { return .zero }
        
        var containerViewFrame = containerView.frame.inset(by: containerView.safeAreaInsets)
        
        let insets = self.isKeyboardVisible ? self.keyboardPopoverInsets : self.popoverInsets
        containerViewFrame = containerViewFrame.inset(by: insets)
        
        containerViewFrame.size.height -= max(0, self.keyboardHeight)
        
        let maxSize = containerViewFrame.size
        let preferredContentSize: CGSize
        if let trackingScrollView, trackingScrollView.contentSize != .zero {
            preferredContentSize = trackingScrollView.contentSize
        } else {
            preferredContentSize = presentedViewController.preferredContentSize
        }
        
        let dxInset = max((maxSize.width - preferredContentSize.width) / 2, 0)
        let dyInset = max((maxSize.height - preferredContentSize.height) / 2, 0)
        
        return containerViewFrame.insetBy(dx: dxInset, dy: dyInset)
    }
    
    open override func containerViewWillLayoutSubviews() {
        guard (presentedView?.transform.isIdentity ?? false) else { return }
        
        if presentedViewController.isBeingPresented || presentedViewController.isBeingDismissed {
            presentedView?.frame = frameOfPresentedViewInContainerView
            topStackView.frame = frameOfTopStackViewInContainerView
        } else {
            UIView.animate(withDuration: 1 / 3, delay: 0, options: [.layoutSubviews], animations: {
                self.presentedView?.frame = self.frameOfPresentedViewInContainerView
                self.topStackView.frame = self.frameOfTopStackViewInContainerView
            })
        }
    }
    
    open override func preferredContentSizeDidChange(forChildContentContainer _: UIContentContainer) {
        containerView?.setNeedsLayout()
    }
}

// MARK: - topStackView

extension BlurPopoverPresentationController {
    var frameOfTopStackViewInContainerView: CGRect {
        let presentedViewFrame = presentedView?.frame ?? frameOfPresentedViewInContainerView
        
        let width = presentedViewFrame.width - 15
        let height = Constants.topStackViewHeight
        
        let x = presentedViewFrame.minX + 10
        let y = presentedViewFrame.minY - height - 10
        
        let size = CGSize(width: width, height: height)
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        
        return frame
    }
    
    private func setupTopStackView() {
        containerView?.addSubview(topStackView)
        
        [titleLabel, dismissButton].forEach {
            topStackView.addArrangedSubview($0)
        }
        
        popoverInsets.top += Constants.topStackViewHeight
        topStackView.frame = frameOfTopStackViewInContainerView
        
        topStackView.alpha = 0
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.topStackView.alpha = 1
        })
    }
}

// MARK: - PresentedView Setup
extension BlurPopoverPresentationController {
    private func setupPresentedView() {
        guard let presentedView = self.presentedView else { return }
        
        presentedView.layer.cornerRadius = 15
        presentedView.layer.masksToBounds = true
        
        addDismissPanGesture()
        
        titleObserver = presentedViewController.observe(
            \.title,
             options: [.old, .new, .initial]
        ) { [weak self] viewController, _ in
            self?.titleLabel.text = viewController.title
        }
        
        autoDetectScrollView()
    }
    
    private func addDismissPanGesture() {
        if let view = containerView { addPanGestureTo(view: view) }
        if let view = presentedView { addPanGestureTo(view: view) }
    }
    
    private func addPanGestureTo(view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panning))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }
    
    private func autoDetectScrollView() {
        guard trackingScrollView == nil else { return }
        let viewController = presentedViewController
        
        if let navController = viewController as? UINavigationController,
            let topViewController = navController.topViewController {
            if let tvc = topViewController as? UITableViewController {
                trackingScrollView = tvc.tableView
            } else {
                if let scrollView = (topViewController.view.subviews.first as? UIStackView)?.arrangedSubviews.first as? UIScrollView {
                    trackingScrollView = scrollView
                } else if let scrollView = topViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                    trackingScrollView = scrollView
                }
            }
            
        } else if let tvc = viewController as? UITableViewController {
            trackingScrollView = tvc.tableView
        } else if let scrollView = viewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            trackingScrollView = scrollView
        }
    }
}

// MARK: - Blur Background Setup

private extension BlurPopoverPresentationController {
    private func restartBlurAnimation() {
        blurAnimator.stopAnimation(true)
        
        blurView.effect = nil
        
        blurAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.blurView.effect = self.blurEffect
        }
        
        blurAnimator.fractionComplete = blurFractionComplete
    }
    
    private func setupBlurView() {
        blurAnimator.fractionComplete = blurFractionComplete
        
        containerView?.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: containerView!.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView!.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView!.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView!.bottomAnchor)
        ])
    }
    
    private func removeBlurView() {
        blurAnimator.stopAnimation(true)
    }
}

// MARK: - Gesture Recognizers Panning

private extension BlurPopoverPresentationController {
    @objc private func panning(_ pan: UIPanGestureRecognizer) {
        guard let containerView = self.containerView, let presentedView = self.presentedView else {
            return
        }
        
        let translation = pan.translation(in: containerView)
        let progress = (translation.y / 2) / containerView.frame.height
        
        switch pan.state {
        case .began, .changed:
            
            let newScale = newScaleTransform(translation: translation, progress: progress)
            
            let newTranslation = translationTransform(translation: translation)
            presentedView.transform = newTranslation.concatenating(newScale)
            
            if translation.y > 0 {
                topStackView.transform = .init(translationX: newTranslation.tx, y: -translation.y)
            } else {
                topStackView.transform = newTranslation
            }
            
            blurAnimator.fractionComplete = blurFractionComplete - progress
        case .ended, .cancelled, .failed:
            endAllPanning(progress: progress, velocity: pan.velocity(in: containerView))
        default: break
        }
    }
    
    private func endAllPanning(progress: CGFloat, velocity: CGPoint) {
        let reachedDismissScale = progress >= 1 - Constants.scaleLimit
        let reachedDismissVelocity = velocity.y > Constants.dismissVelocityLimit
        
        if reachedDismissScale || reachedDismissVelocity {
            presentedViewController.dismiss(animated: true)
        } else {
            snapPresentedViewToOriginalCenter()
            blurAnimator.fractionComplete = blurFractionComplete
        }
    }
    
    private func newScaleTransform(translation: CGPoint, progress: CGFloat) -> CGAffineTransform {
        var scale = CGFloat()
        
        if translation.y > 0 {
            scale = 1 - progress
            scale = max(scale, Constants.scaleLimit) // force a minimum value
        } else {
            scale = 1 - (progress / 10)
        }
        
        return .init(scaleX: scale, y: scale)
    }
    
    private func translationTransform(translation: CGPoint) -> CGAffineTransform {
        var y = CGFloat()
        
        if translation.y > 0 {
            y = translation.y
        } else {
            // reduce the translation by 15 times
            // to make the effect of rubbing the view when the translation is < 0
            y = translation.y / 15
        }
        
        return .init(translationX: translation.x / 20, y: y)
    }
    
    private func snapPresentedViewToOriginalCenter() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.65,
            initialSpringVelocity: 0.5,
            options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.presentedView?.transform = .identity
                self.topStackView.transform = .identity
            }
        )
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BlurPopoverPresentationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let scrollView = trackingScrollView else {
            return true
        }
        
        guard scrollView.isTracking else {
            // That means that touches was outside the scrollView
            // So we need to return true to begin this pan gesture
            return true
        }
        
        if scrollView.isAtTop && pan.direction == .down || scrollView.isAtBottom && pan.direction == .up {
            return true
        }
        
        if pan.direction == .left || pan.direction == .right {
            return false
        }
        
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        trackingScrollView?.gestureRecognizers?.contains(otherGestureRecognizer) ?? false
    }
}

// MARK: - Keyboard Notifications

private extension BlurPopoverPresentationController {
    private func registerKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc private func dismissPresentedVC() {
        presentedViewController.dismiss(animated: true)
    }
    
    @objc private func adjustForKeyboard(notification: Notification) {
        guard
            let info = notification.userInfo,
            let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        switch notification.name {
        case UIResponder.keyboardWillShowNotification:
            isKeyboardVisible = true
        case UIResponder.keyboardWillHideNotification:
            keyboardHeight = 0
            isKeyboardVisible = false
        case UIResponder.keyboardWillChangeFrameNotification:
            keyboardHeight = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        default: break
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .init(rawValue: curve), animations: {
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            self.topStackView.frame = self.frameOfTopStackViewInContainerView
        })
    }
}

// MARK: - Application Notifications

private extension BlurPopoverPresentationController {
    private func registerApplicationNotificationsObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restartBlurAnimation()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.removeBlurView()
        }
    }
}
