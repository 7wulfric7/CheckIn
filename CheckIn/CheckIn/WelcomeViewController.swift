//
//  WelcomeViewController.swift
//  CheckIn
//
//  Created by Deniz Adil on 14.1.21.
//

import UIKit
import Firebase
import AuthenticationServices
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit

class WelcomeViewController: UIViewController, ASAuthorizationControllerDelegate {

    @IBOutlet weak var onSignInWithFacebook: UIButton!
    @IBOutlet weak var onSignInWithGoogle: GIDSignInButton!
    @IBOutlet weak var onSignInWithEmail: UIButton!
    @IBOutlet weak var onCreateAccount: UIButton!
    @IBOutlet weak var googleHolderView: UIView!
    @IBOutlet weak var facebookHolderView: UIView!
    @IBOutlet weak var signInWithEmailHolderView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        signInWithAppleButton()
        setBordersForButtons()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        if Auth.auth().currentUser != nil {
            DataStore.shared.getUser(uid: Auth.auth().currentUser!.uid) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                DataStore.shared.localUser = user
                self.performSegue(withIdentifier: "Home", sender: nil)
            }
        } else if GIDSignIn.sharedInstance()?.currentUser != nil {
            GIDSignIn.sharedInstance().signIn()
            self.performSegue(withIdentifier: "Home", sender: nil)
        } else {
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    func setBordersForButtons() {
        
        facebookHolderView.layer.borderWidth = 1.0
        facebookHolderView.layer.borderColor = UIColor.gray.cgColor
        facebookHolderView.layer.cornerRadius = 6.0
       
        googleHolderView.layer.borderWidth = 1.0
        googleHolderView.layer.borderColor = UIColor.gray.cgColor
        googleHolderView.layer.cornerRadius = 6.0
        signInWithEmailHolderView.layer.cornerRadius = 6.0
        signInWithEmailHolderView.layer.borderWidth = 1.0
        signInWithEmailHolderView.layer.borderColor = UIColor.gray.cgColor
    }
    
    func signInWithAppleButton() {
        let appleButton = ASAuthorizationAppleIDButton(type: .default, style: .black)
        appleButton.layer.borderWidth = 1.0
        appleButton.layer.cornerRadius = 6.0
        appleButton.layer.borderColor = UIColor.gray.cgColor
        appleButton.layer.masksToBounds = true
        appleButton.addTarget(self, action: #selector(buttonRequest), for: .touchUpInside)
        appleButton.frame = CGRect(x: 0, y: 0, width: 255, height: 40)
        appleButton.center = view.center
        self.view.addSubview(appleButton)
    }
    
    @objc func buttonRequest() {
        let appProvider = ASAuthorizationAppleIDProvider()
        let request = appProvider.createRequest()
        request.requestedScopes = [.email, .fullName]
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = self
        authController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appID = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = appID.user
            let fullName = appID.fullName
            let emailID = appID.email
            print("UserID: \(userId), Full Name: \(String(describing: fullName)), email: \(String(describing: emailID))")
            let appleProvider = ASAuthorizationAppleIDProvider()
            appleProvider.getCredentialState(forUserID: userId) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    print("Apple ID Credentials are valid")
                    break
                case .revoked:
                    print("User as revoked access to the app using Apple ID")
                    break
                case .notFound:
                    print("User was not found or has never signed in using Apple ID")
                    break
                default:
                    break
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error.localizedDescription)
    }
    
    @IBAction func onSignInWithFacebook(_ sender: UIButton) {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            guard let accessToken = AccessToken.current else {
                print("Failed to get access token")
                return
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            Auth.auth().signIn(with: credential) { (user, error) in
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    let alertController = UIAlertController(title: "Login error", message: error.localizedDescription, preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true, completion: nil)
                    return
                } else {
                    if Auth.auth().currentUser != nil {
                        self.performSegue(withIdentifier: "Home", sender: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func onSignInWithGoogle(_ sender: GIDSignInButton) {
        if GIDSignIn.sharedInstance()?.currentUser == nil {
            GIDSignIn.sharedInstance().signIn()
            self.performSegue(withIdentifier: "Home", sender: nil)
        }
    }
    
    @IBAction func onSignInWithEmail(_ sender: UIButton) {
        performSegue(withIdentifier: "SignInViewController", sender: nil)
    }
    
    @IBAction func onCreateAccount(_ sender: UIButton) {
        performSegue(withIdentifier: "SetupProfileViewController", sender: nil)
    }
}
