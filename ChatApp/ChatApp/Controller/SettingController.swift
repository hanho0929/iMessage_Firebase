//
//  SettingController.swift
//  ChatApp
//
//  Created by hanho on 2/1/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import AccountKit
import Firebase

class SettingController: UIViewController {
    
    var accountKit: AKFAccountKit!
    
    let nameText: UILabel = {
        let label = UILabel()
        //label.text = "My name: Han"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let phoneText: UILabel = {
        let label = UILabel()
        //label.text = "My number: +1 6262724715"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(inputsContainerView)
        setupInputsContainerView()
        self.accountKit = AKFAccountKit(responseType: AKFResponseType.accessToken)
        accountKit.requestAccount { (account, error) in
            if error != nil {
                print(error)
                return
            }
            let uid = account?.accountID
            Database.database().reference().child("users").child(uid!).observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let user = User(dictionary: dictionary)
                    
                    self.nameText.text = "My name: \(user.name!)"
                    self.phoneText.text = "My number is: \(user.phoneNumber!)"
                }
            })
        }
    }
    
    
    func setupInputsContainerView() {
        // need x, y, width, height constraints
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant:100).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        inputsContainerView.addSubview(nameText)
        inputsContainerView.addSubview(phoneText)
        
        // need x, y, width, height constraints -- nameText
        nameText.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameText.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameText.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameText.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2).isActive = true
        
        // need x, y, width, height constraints -- phoneTextField
        phoneText.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        phoneText.topAnchor.constraint(equalTo: nameText.bottomAnchor).isActive = true
        phoneText.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        phoneText.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2).isActive = true
    }
}
