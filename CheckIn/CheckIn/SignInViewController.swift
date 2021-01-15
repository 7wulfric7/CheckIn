//
//  SignInViewController.swift
//  CheckIn
//
//  Created by Deniz Adil on 14.1.21.
//

import UIKit
import FirebaseAuth
import Firebase
import SVProgressHUD

class SignInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var onSignIn: UIButton!
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle()
        setBackButton()
        setBorders()
        
    }
    
    func setBorders() {
        onSignIn.layer.masksToBounds = true
        onSignIn.layer.cornerRadius = 6
    }
    
    func setBackButton() {
        let back = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        back.setImage(UIImage(named: "BackButton"), for: .normal)
        back.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: back)
    }
    
    @objc func onBack() {
        navigationController?.popViewController(animated: true)
    }
    
    func setTitle() {
        title = "Sign In"
        let titleAttributes = [NSAttributedString.Key.foregroundColor:UIColor.darkGray, NSAttributedString.Key.font:UIFont.systemFont(ofSize: 13, weight: .medium)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes as [NSAttributedString.Key : Any]
    }
    
    @IBAction func onSignIn(_ sender: UIButton) {
        guard let email = emailTextField.text, email != "" else {
            showErrorWith(title: "Error", msg: "Please enter your e-mail")
            return
        }
        guard email.isValidEmail() else {
            showErrorWith(title: "Error", msg: "Please enter a valid e-mail")
            return
        }
        guard let password = passwordTextField.text, password != "" else {
            showErrorWith(title: "Error", msg: "Please enter your password")
            return
        }
        guard password.count >= 6 else {
            showErrorWith(title: "Error", msg: "Password must contain at least 6 characters")
            return
        }
        SVProgressHUD.show()
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                let specificError = error as NSError
                if specificError.code == AuthErrorCode.invalidEmail.rawValue && specificError.code == AuthErrorCode.wrongPassword.rawValue {
                    self.showErrorWith(title: "Error", msg: "Incorect email or password")
                    return
                }
                if specificError.code == AuthErrorCode.userDisabled.rawValue {
                    self.showErrorWith(title: "Error", msg: "Your account was disabled")
                    return
                }
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            if let authResult = authResult {
                self.getLocalUserData(uid: authResult.user.uid)
            }
        }
        performSegue(withIdentifier: "HomeViewController", sender: nil)
    }
    
    func getLocalUserData(uid: String) {
        SVProgressHUD.show()
        DataStore.shared.getUser(uid: uid) { (user, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            if let user = user {
                DataStore.shared.localUser = user
                return
            }
        }
    }

}
