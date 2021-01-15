//
//  MyCheckInsCollectionViewCell.swift
//  CheckIn
//
//  Created by Deniz Adil on 14.1.21.
//

import UIKit
import Kingfisher

class MyCheckInsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var country: UILabel!
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var coordinates: UILabel!
    
    var feedItem: Feed?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userPhoto.layer.cornerRadius = 20
        userPhoto.layer.masksToBounds = true
    }
    
    func setupCell(feedItem: Feed) {
        self.feedItem = feedItem
        image.kf.setImage(with: URL(string: feedItem.imageUrl!))
        setDate(feedItem: feedItem)
        fetchCreatorDetails(feedItem: feedItem)
    }
    
    func fetchCreatorDetails(feedItem: Feed) {
        guard let creatorId = feedItem.creatorId else { return }
        DataStore.shared.getUser(uid: creatorId) { (user, error) in
            if let user = user {
                self.userName.text = user.name
                if let imageUrl = user.image {
                    self.userPhoto.kf.setImage(with: URL(string: imageUrl))
                } else {
                    self.userPhoto.image = UIImage(named: "user")
                }
            }
        }
    }
    
    func setDate(feedItem: Feed) {
        let date = Date(with: feedItem.createdAt!)
        time.text = date?.timeAgoDisplay()
    }
}
