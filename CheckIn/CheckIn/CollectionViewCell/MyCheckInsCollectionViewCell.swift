//
//  MyCheckInsCollectionViewCell.swift
//  CheckIn
//
//  Created by Deniz Adil on 14.1.21.
//

import UIKit
import Kingfisher
import CoreLocation
import Firebase
import GoogleSignIn

class MyCheckInsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var country: UILabel!
    @IBOutlet weak var latitude: UILabel!
    @IBOutlet weak var longitude: UILabel!
    
    
    var feedItem: Feed?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userPhoto.layer.cornerRadius = 20
        userPhoto.layer.masksToBounds = true
    }
    
    func setupCell(feedItem: Feed, user: User) {
        self.feedItem = feedItem
        image.kf.setImage(with: URL(string: feedItem.imageUrl!))
        setDate(feedItem: feedItem)
        fetchCreatorDetails(feedItem: feedItem)
    }
    
    func fetchCreatorDetails(feedItem: Feed) {
//        currentFacebookUser()
//        currentGoogleUser()
        guard let creatorId = feedItem.creatorId else { return }
        DataStore.shared.getUser(uid: creatorId) { (user, error) in
            if let user = user {
                self.userName.text = user.name
                if let imageUrl = user.image {
                    self.userPhoto.kf.setImage(with: URL(string: imageUrl))
                } else {
                    self.userPhoto.image = UIImage(named: "user")
                }
//                self.time.text = "\(feedItem.createdAt ?? 0.0)"
                self.country.text = feedItem.location
                self.latitude.text = "lat: \(feedItem.latitude ?? "0.0")"
                self.longitude.text = "long: \(feedItem.longitude ?? "0.0")"
            }
        }
    }
    
    func setDate(feedItem: Feed) {
        let date = Date(with: feedItem.createdAt!)
        time.text = date?.timeAgoDisplay()
    }
    
//    func currentFacebookUser() {
//        if let currentUser = Auth.auth().currentUser {
//            userName.text = currentUser.displayName
//            guard let photo = currentUser.photoURL, let data = NSData(contentsOf: photo) else { return }
//            userPhoto.image = UIImage(data: data as Data)
//        }
//    }
//    
//    func currentGoogleUser() {
//        if let currentUser: GIDGoogleUser = GIDSignIn.sharedInstance()?.currentUser {
//            userName.text = currentUser.profile.name
//            if currentUser.profile.hasImage {
//               guard let photo = currentUser.profile.imageURL(withDimension: 200), let data = NSData(contentsOf: photo) else { return }
//                self.userPhoto.image = UIImage(data: data as Data)
//            }
//        }
//    }
    
}


