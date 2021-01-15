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

class HomeViewController: UIViewController {
    
    @IBOutlet weak var onSignOut: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    

    @IBAction func onSignOut(_ sender: UIButton) {
        GIDSignIn.sharedInstance()?.signOut()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        performSegue(withIdentifier: "WelcomeViewController", sender: nil)
    }
    
}
