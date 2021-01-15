//
//  LoadingCollectionViewCell.swift
//  CheckIn
//
//  Created by Deniz Adil on 15.1.21.
//

import UIKit
import SnapKit

class LoadingCollectionViewCell: UICollectionViewCell {
    let activityIndicator: UIActivityIndicatorView = {
       let activityIndicatior = UIActivityIndicatorView(style: .medium)
       activityIndicatior.color = .black
       activityIndicatior.translatesAutoresizingMaskIntoConstraints = false
       activityIndicatior.isHidden = false
       return activityIndicatior
   }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(named: "ThirdGray")
        label.text = "Loading data..."
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupViews() {
        contentView.addSubview(activityIndicator)
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(20)
        }
        activityIndicator.snp.makeConstraints { (make) in
            make.size.equalTo(50)
            make.bottom.equalTo(label.snp.top).inset(10)
            make.center.centerX.equalToSuperview()
        }
    }
}
