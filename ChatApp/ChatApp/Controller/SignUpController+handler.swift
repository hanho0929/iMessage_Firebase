//
//  LoginController+handler.swift
//  ChatApp
//
//  Created by hanho on 1/30/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import Firebase

extension SignUpController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        
    }
    
    @objc func handleContinue() {
        let inputState = UUID().uuidString
        let vc = (accountKit?.viewControllerForPhoneLogin(with: nil, state: inputState))!
        vc.enableSendToFacebook = true
        self.prepareLoginViewController(loginViewController: vc)
        self.present(vc as UIViewController, animated: true, completion: nil)
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }

    
    fileprivate func registerUserIntoFirebaseWithAccount(uid : String, values: [String: Any]) {
        
        let ref = Database.database().reference()
        let userReference = ref.child("users").child(uid)
        userReference.updateChildValues(values) { (err, ref) in
                if err != nil {
                    print(err)
                    return
                }
                print("Saved user successfully into Firebase db")
        }
        
    }
    
    func uploadImageToFirebase() {
        accountKit.requestAccount{
            (account, error) -> Void in
            
            if error != nil {
                print(error)
                return
            }
            guard let uid = account?.accountID else { return }

        
            let imageName = NSUUID().uuidString
        
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            let uploadData = self.profileImageView.image?.jpegData(compressionQuality: 0.1) as! Data
            
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error)
                }
                
                storageRef.downloadURL(completion: { (url, error) in
                    if error != nil {
                        print(error)
                    }
                    guard let profileImageUrl = url?.absoluteString else { return }
                    let values = ["name": self.nameTextField.text, "phoneNumber": account?.phoneNumber?.stringRepresentation(), "profileImageUrl": profileImageUrl] as [String : Any]
                    self.registerUserIntoFirebaseWithAccount(uid: uid, values: values)
                })
                
            }
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        var selectedImageFromPicker: UIImage?
        
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            selectedImageFromPicker = editedImage
            print(editedImage)
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }

        dismiss(animated: true, completion: nil)
        
     }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
    
}
