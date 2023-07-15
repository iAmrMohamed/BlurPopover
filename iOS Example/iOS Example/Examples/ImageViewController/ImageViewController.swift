//
//  ImageViewController.swift
//  iOS Example
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit

class ImageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ImageViewController"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        preferredContentSize = .init(width: view.frame.width, height: height)
    }
}
