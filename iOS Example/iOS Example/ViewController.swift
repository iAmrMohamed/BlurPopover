//
//  ViewController.swift
//  iOS Example
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit
import BlurPopover

class ViewController: UITableViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: presentImageViewControllerExample()
            default: break
            }
        case 1:
            switch indexPath.row {
            case 0: presentCustomLayoutExample()
            case 1: presentTableViewExample()
            case 2: presentScrollViewExample()
            case 3: presentBaseInheritedClassExample()
            default: break
            }
        default: break
        }
        
    }
    
    private func presentCustomLayoutExample() {
        let dvc = CustomViewController()
        dvc.modalPresentationStyle = .custom
        dvc.transitioningDelegate = self
        present(dvc, animated: true)
    }
    
    private func presentImageViewControllerExample() {
        let dvc = ImageViewController()
        dvc.modalPresentationStyle = .custom
        
        dvc.transitioningDelegate = BlurPopoverSharedTransitioningDelegate.newTransitioningDelegate(
            presentingSourceView: imageView,
            dismissingSourceView: imageView
        )
        
        present(dvc, animated: true)
    }
    
    private func presentTableViewExample() {
        let dvc = TableViewController()
        dvc.modalPresentationStyle = .custom
        dvc.transitioningDelegate = self
        present(dvc, animated: true)
    }
    
    private func presentScrollViewExample() {
        let dvc = ScrollViewController()
        dvc.modalPresentationStyle = .custom
        dvc.transitioningDelegate = self
        present(dvc, animated: true)
    }
    
    private func presentScrollUsingTheSharedTransitioningDelegateViewExample() {
        let dvc = ScrollViewController()
        dvc.modalPresentationStyle = .custom
        dvc.transitioningDelegate = BlurPopoverSharedTransitioningDelegate.newTransitioningDelegate()
        present(dvc, animated: true)
    }
    
    private func presentBaseInheritedClassExample() {
        // notice we don't need to set the modalPresentationStyle
        // or the transitioningDelegate because they are set
        // automatically in the BlurPopoverBaseViewController
        let dvc = BaseInheritedClassViewController()
        present(dvc, animated: true)
    }
}

extension ViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        BlurPopoverPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
