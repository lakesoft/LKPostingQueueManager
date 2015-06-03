//
//  LKPostingQueueTableViewCell.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/31.
//
//

import UIKit

class LKPostingQueueTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
