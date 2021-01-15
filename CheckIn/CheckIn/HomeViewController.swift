//
//  HomeViewController.swift
//  CheckIn
//
//  Created by Deniz Adil on 14.1.21.
//

import UIKit
import Firebase
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit
import SVProgressHUD
import CoreLocation
import MapKit

enum CollectionData: Equatable {
    case feedItems([Feed])
    case loading
    static func == (lhs: CollectionData, rhs: CollectionData) -> Bool {
        switch (lhs, rhs) {
        case (.feedItems(_), .feedItems(_)):
            return true
        case (.loading, .loading):
            return true
        default:
            return false
        }
    }
}

class HomeViewController: UIViewController {
    
    @IBOutlet weak var noCheckIns: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var onPost: UIButton!
    
    var refreshControl = UIRefreshControl()
    var feedItems = [Feed]()
    private var collectionData: [CollectionData] = [.feedItems([])]
    private var pageSize = 5
    private var lastFeedDocument: DocumentSnapshot?
    var cities = [City]()
    var filteredCities = [City]()
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setTitle()
        setLogOutButton()
        customizeButton(onPost: onPost)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh(_:)), name: Notification.Name("ReloadFeedAfterUserAction"), object: nil)
    }
    
    @IBAction func onPost(_ sender: UIButton) {
        performSegue(withIdentifier: "LocationViewController", sender: nil)
    }
    func setTitle() {
        title = "Home Screen"
        let titleAttributes = [NSAttributedString.Key.foregroundColor:UIColor.darkGray, NSAttributedString.Key.font:UIFont.systemFont(ofSize: 13, weight: .medium)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes as [NSAttributedString.Key : Any]
    }
    
    func customizeButton(onPost: UIButton) {
        onPost.layer.shadowColor = UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 0.50).cgColor
        onPost.layer.shadowOpacity = 0.8
        onPost.layer.shadowOffset = CGSize(width: 2.0, height: 3.0)
    }
    
    func setLogOutButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 14))
        button.setTitle("LogOut", for: .normal)
        let titleColor = UIColor.systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
        button.setTitleColor(titleColor, for: .normal)
        button.addTarget(self, action: #selector(onLogOut), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
    
    func setupCollectionView() {
        collectionView.register(LoadingCollectionViewCell.self, forCellWithReuseIdentifier: "LoadingCollectionViewCell")
        collectionView.register(UINib(nibName: "MyCheckInsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MyCheckInsCollectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: collectionView.frame.width, height: 343)
            layout.estimatedItemSize = CGSize(width: collectionView.frame.width, height: 343)
        }
    }
    @objc func onLogOut() {
        GIDSignIn.sharedInstance()?.signOut()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        performSegue(withIdentifier: "WelcomeViewController", sender: nil)
    }
    
    @objc func refresh(_ refreshControl: UIRefreshControl) {
        fetchFeedItems(isRefresh: true)
    }
    
    private func fetchFeedItems(isRefresh: Bool = false) {
        SVProgressHUD.show()
        if isRefresh {
            lastFeedDocument = nil
            feedItems.removeAll()
        }
        DataStore.shared.fetchFeedItems(pageSize: pageSize, lastDocument: lastFeedDocument) { (feeds, error, lastDocument)  in
            SVProgressHUD.dismiss()
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            if let error = error {
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            self.lastFeedDocument = lastDocument
            self.collectionData.removeAll()
            if let feeds = feeds {
                self.collectionData.append(.feedItems(self.feedItems))
                if self.feedItems.count == 0 {
                    self.noCheckIns.isHidden = false
                } else {
                    self.noCheckIns.isHidden = true
                }
                if feeds.count == self.pageSize {
                    self.collectionData.append(.loading)
                }
                self.sortAndReload()
            }
        }
    }
    
    func sortAndReload() {
        self.feedItems.sort { (feedOne, feedTwo) -> Bool in
            guard let oneDate = feedOne.createdAt else { return false }
            guard let twoDate = feedTwo.createdAt else { return false }
            return oneDate > twoDate
        }
        collectionView.reloadData()
    }
    
}
extension HomeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is LoadingCollectionViewCell {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              self.fetchFeedItems()
          }
        }
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            let data = collectionData[section]
            switch data {
            case .loading:
                return 1
            case .feedItems(let feedItems):
                return feedItems.count
            }
        }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = collectionData[indexPath.section]
        switch data {
        case .feedItems(let items):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCheckInsCollectionViewCell", for: indexPath) as! MyCheckInsCollectionViewCell
            let feed = items[indexPath.row]
            cell.setupCell(feedItem: feed)
            return cell
            
        case .loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoadingCollectionViewCell", for: indexPath) as! LoadingCollectionViewCell
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.isHidden = false
            return cell
        }
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let data = collectionData[indexPath.section]
        switch data {
        case .loading:
            return CGSize(width: collectionView.frame.width, height: 343)
        default:
            return CGSize(width: collectionView.frame.width, height: 343)
        }
    }
}
