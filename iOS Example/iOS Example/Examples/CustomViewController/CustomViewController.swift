//
//  CustomViewController.swift
//  iOS Example
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit

class CustomViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CustomViewController"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        preferredContentSize = .init(width: view.frame.width, height: height)
    }
}
