//
//  UIScrollView+Extensions.swift
//  
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit

public extension UIScrollView {
    /// Determines if a scrollView offset.y is at the top
    /// Takes into account the adjustedContentInset.top
    /// Values gets rounded before being checked
    var isAtTop: Bool {
        contentOffset.y.rounded() <= -adjustedContentInset.top.rounded()
    }
    
    /// Determines if a scrollView offset.y is at the bottom
    /// Takes into account the adjustedContentInset.bottom
    /// Values gets rounded before being checked
    var isAtBottom: Bool {
        contentOffset.y.rounded() >= verticalOffsetForBottom.rounded()
    }
    
    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = adjustedContentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
}
