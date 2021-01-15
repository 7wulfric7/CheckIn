//
//  SetupProfileViewController.swift
//  CheckIn
//
//  Created by Deniz Adil on 14.1.21.
//

import UIKit
import FirebaseAuth
import Firebase
import SVProgressHUD
import CoreServices
import SwiftPhotoGallery

class SetupProfileViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var imageHolderView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var onSaveAccount: UIButton!
    @IBOutlet weak var onUploadPhoto: UIButton!
    @IBOutlet weak var userPhoto: UIImageView!
    
    var user: User?
    private var pickedImage: UIImage?
    private var galleryImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        setTitle()
        setBackButton()
        setBorders()
        
    }
    
    func setBorders() {
        imageHolderView.layer.cornerRadius = 35
        imageHolderView.layer.masksToBounds = true
        onSaveAccount.layer.cornerRadius = 6
    }
    func setAddPhotoButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 14))
        button.setTitle("Add photo", for: .normal)
        let titleColor = UIColor.systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
        button.setTitleColor(titleColor, for: .normal)
        button.addTarget(self, action: #selector(onAddPhoto), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
    
    @objc func onAddPhoto() {
        openImagePicker()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setKeyboardObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }
    
    func setKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = .zero
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
        title = "Setup your profile"
        let titleAttributes = [NSAttributedString.Key.foregroundColor:UIColor.darkGray, NSAttributedString.Key.font:UIFont.systemFont(ofSize: 13, weight: .medium)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes as [NSAttributedString.Key : Any]
    }
    
    @IBAction func onUploadPhoto(_ sender: UIButton) {
        openImagePicker()
        setAddPhotoButton()
    }
    
    @IBAction func onSaveAccount(_ sender: UIButton) {
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
        guard password.count >= 5 else {
            showErrorWith(title: "Error", msg: "Password must contain at least 6 characters")
            return
        }
        SVProgressHUD.show()
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                let specificError = error as NSError
                if specificError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    self.showErrorWith(title: "Error", msg: "Email already in use!")
                    return
                }
                if specificError.code == AuthErrorCode.weakPassword.rawValue {
                    self.showErrorWith(title: "Error", msg: "Your password is too weak")
                    return
                }
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            if let authResult = authResult {
                self.saveUser(uid: authResult.user.uid)
            }
        }
        guard let localUser = user else {return}
        DataStore.shared.setUserData(user: localUser) { (success, error) in
            if let error = error {
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            if success {
                DataStore.shared.localUser = localUser
            }
        }
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                let specificError = error as NSError
               
                if specificError.code == AuthErrorCode.invalidEmail.rawValue && specificError.code == AuthErrorCode.wrongPassword.rawValue {
                    self.showErrorWith(title: "Error", msg: "Incorect email or password")
                    return
                }
                if specificError.code == AuthErrorCode.userDisabled.rawValue {
                    self.showErrorWith(title: "Error", msg: "You account was disabled")
                    return
                }
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            if let authResult = authResult {
                self.getLocalUserData(uid: authResult.user.uid)
            }
        }
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
    
    func saveUser(uid: String) {
        var user = User(id: uid)
        user.name = fullNameTextField.text
        user.email = emailTextField.text
        guard let userId = user.id else {return}
        DataStore.shared.uploadImage(image: (pickedImage ?? UIImage(named: "user"))!, itemId: userId) { (url, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let url = url {
                user.image = url.absoluteString
                DataStore.shared.setUserData(user: user) { (_, _) in }
            }
        }
        SVProgressHUD.show()
        DataStore.shared.setUserData(user: user) { [self] (success, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                self.showErrorWith(title: "Error", msg: error.localizedDescription)
                return
            }
            if success {
                DataStore.shared.localUser = self.user
                self.continueToHome()
            }
        }
    }
    
    func continueToHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Home")
        present(controller, animated: true, completion: nil)
        navigationController?.popToRootViewController(animated: false)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            self.pickedImage = image
            userPhoto.image = pickedImage
            userPhoto.layer.cornerRadius = 28
            userPhoto.layer.masksToBounds = true
        }
    }
    
    private func openImagePicker() {
        let actionSheet = UIAlertController(title: "Profile photo", message: "Please pick an image", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) { _ in
            self.openImagePicker(sourceType: .camera)
        }
        let library = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(camera)
        actionSheet.addAction(library)
        actionSheet.addAction(cancel)
        onUploadPhoto.isHidden = true
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        if sourceType == .camera {
            imagePicker.cameraDevice = .front
        }
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    
    func galleryDidTapToClose(gallery: SwiftPhotoGallery) {
        gallery.dismiss(animated: true, completion: nil)
    }
    
    func numberOfImagesInGallery(gallery: SwiftPhotoGallery) -> Int {
        return galleryImages.count
    }
    
    func imageInGallery(gallery: SwiftPhotoGallery, forIndex: Int) -> UIImage? {
        let image = galleryImages[forIndex]
        return image
    }
}
