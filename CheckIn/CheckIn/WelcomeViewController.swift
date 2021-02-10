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
import SVProgressHUD

class WelcomeViewController: UIViewController, ASAuthorizationControllerDelegate {
    
    @IBOutlet weak var onSignInWithFacebook: UIButton!
    @IBOutlet weak var onSignInWithGoogle: UIButton!
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
        if Auth.auth().currentUser != nil {
            DataStore.shared.getUser(uid: Auth.auth().currentUser!.uid) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                DataStore.shared.localUser = user
                self.performSegue(withIdentifier: "Home", sender: nil)
            }
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
        facebookHolderView.layer.cornerRadius = 20.0
        facebookHolderView.layer.borderColor = UIColor.white.cgColor
        facebookHolderView.layer.borderWidth = 1.0
        onSignInWithFacebook.layer.masksToBounds = true
        googleHolderView.layer.cornerRadius = 20.0
        googleHolderView.layer.borderColor = UIColor.white.cgColor
        googleHolderView.layer.borderWidth = 1.0
        onSignInWithGoogle.layer.masksToBounds = true
        signInWithEmailHolderView.layer.cornerRadius = 20.0
        signInWithEmailHolderView.layer.borderColor = UIColor.white.cgColor
        signInWithEmailHolderView.layer.borderWidth = 1.0
        onSignInWithEmail.layer.masksToBounds = true
    }
    
    func signInWithAppleButton() {
        let appleButton = ASAuthorizationAppleIDButton(type: .default, style: .black)
        appleButton.layer.cornerRadius = 20.0
        appleButton.layer.borderColor = UIColor.white.cgColor
        appleButton.layer.borderWidth = 1.0
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
                    guard let currentUser = user?.user else {return}
                    var cUser = User(id: currentUser.uid)
                        cUser.name = currentUser.displayName
                        cUser.email = currentUser.email
                        guard let photo = currentUser.photoURL?.absoluteString else {return}
                        cUser.image = photo
                    DataStore.shared.setUserData(user: cUser) { (success, error) in
                        if let error = error {
                            self.showErrorWith(title: nil, msg: error.localizedDescription)
                            return
                        }
                        if success {
                            DataStore.shared.localUser = cUser
                            self.performSegue(withIdentifier: "Home", sender: nil)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func onSignInWithGoogle(_ sender: UIButton) {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signIn()
    }

    @IBAction func onSignInWithEmail(_ sender: UIButton) {
        performSegue(withIdentifier: "SignInViewController", sender: nil)
    }
    
    @IBAction func onCreateAccount(_ sender: UIButton) {
        performSegue(withIdentifier: "SetupProfileViewController", sender: nil)
    }
}

extension WelcomeViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        let name = user?.profile.name
        let email = user?.profile.email
        print("User Name: \(name ?? "No User"), User Email: \(email ?? "No Email")")
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print("Error occurs when authenticate with Firebase: \(error.localizedDescription)")
            } else {
                guard let currentUser = user?.user else {return}
                var cUser = User(id: currentUser.uid)
                cUser.name = currentUser.displayName
                cUser.email = currentUser.email
                guard let photo = currentUser.photoURL?.absoluteString else {return}
                cUser.image = photo
                DataStore.shared.setUserData(user: cUser) { (success, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    if success {
                        DataStore.shared.localUser = cUser
                        self.performSegue(withIdentifier: "Home", sender: nil)
                    }
                }
            }
        }
    }

        func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
            print("User has disconnected")
        }
}
