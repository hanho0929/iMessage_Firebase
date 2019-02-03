//
//  LoginController.swift
//  ChatApp
//
//  Created by hanho on 1/28/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import AccountKit
import Firebase

class HomeController: UIViewController, AKFViewControllerDelegate {

    
    var accountKit: AKFAccountKit!
    var register: Bool!
    
    let myLabel: UILabel = {
        let label = UILabel()
        label.text = "Chat"
        label.font = UIFont(name: "Helvetica", size: 40)
        label.textAlignment = .center
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.init(hexString: "#2ecc71")
        button.setTitle("SIGN UP", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.titleLabel?.font = UIFont(name: "Helvetica", size: 16)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.setTitle("LOG IN", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont(name: "Helvetica", size: 16)
        button.addTarget(self, action: #selector(handleLogIn), for: .touchUpInside)
        return button
    }()
    
    let homeImageView: UIImageView = {
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.image = UIImage(named: "Han")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // initialize Account Kit
        if accountKit == nil {
            accountKit = AKFAccountKit(responseType: .accessToken)
        }
        
        view.insertSubview(homeImageView, at: 0)
        view.addSubview(myLabel)
        view.addSubview(signUpButton)
        view.addSubview(loginButton)
        
        setupMyLabel()
        setupSignUpButton()
        setupLoginButton()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if accountKit?.currentAccessToken != nil{
            // if the user is already logged in, go to the main screen
            print("Already Logged in\(accountKit?.currentAccessToken?.accountID)")
            
            DispatchQueue.main.async(execute: {
                let uid = self.accountKit?.currentAccessToken?.accountID
                Database.database().reference().child("users").child(uid!).observe(.value, with: { (snapshot) in
                    if snapshot.exists() {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        print("Not register yet")
                    }
                    print(snapshot)
                })
                //self.dismiss(animated: true, completion: nil)
            })
            
        }
        else{
            // Show the login screen
        }
    }
    
    @objc func handleSignUp() {
        self.present(SignUpController(), animated: true, completion: nil)
    }
    @objc func handleLogIn() {
        let inputState = UUID().uuidString
        let vc = (accountKit?.viewControllerForPhoneLogin(with: nil, state: inputState))!
        vc.enableSendToFacebook = true
        self.prepareLoginViewController(loginViewController: vc)
        self.present(vc as UIViewController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func setupMyLabel() {
        myLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        myLabel.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 160).isActive = true
        myLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        myLabel.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
    func setupSignUpButton() {
        signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signUpButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 160).isActive = true
        signUpButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -180).isActive = true
        signUpButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupLoginButton() {
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 12).isActive = true
        loginButton.widthAnchor.constraint(equalTo: signUpButton.widthAnchor).isActive = true
        loginButton.heightAnchor.constraint(equalTo: signUpButton.heightAnchor).isActive = true
    }
    
}


extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}


//extension HomeController: AKFViewControllerDelegate {
//
//    func viewController(viewController: UIViewController!, didCompleteLoginWithAccessToken accessToken: AKFAccessToken!, state: String!) {
//        print("did complete login with access token \(accessToken.tokenString) state \(state)")
//    }
//
//    // handle callback on successful login to show authorization code
//    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWithAuthorizationCode code: String!, state: String!) {
//        print("didCompleteLoginWithAuthorizationCode")
//    }
//
//    func viewControllerDidCancel(_ viewController: (UIViewController & AKFViewController)!) {
//        // ... handle user cancellation of the login process ...
//        print("viewControllerDidCancel")
//    }
//
//    func viewController(_ viewController: (UIViewController & AKFViewController)!, didFailWithError error: Error!) {
//        // ... implement appropriate error handling ...
//        print("\(viewController) did fail with error: \(error.localizedDescription)")
//    }
//
//    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
//
//        print("didCompleteLoginWith + \(accessToken.accountID)")
//        //storeUserToFirebase()
//
//    }
//}


