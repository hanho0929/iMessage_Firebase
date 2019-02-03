//
//  NewViewController.swift
//  ChatApp
//
//  Created by hanho on 1/29/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import Firebase
import AccountKit

class SignUpController: UIViewController, AKFViewControllerDelegate {
    
    
    var accountKit: AKFAccountKit!
    
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "photo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    

    let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter your name"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let nameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    
    let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont(name: "Helvetica", size: 16)
        button.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont(name: "Helvetica", size: 16)
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if accountKit?.currentAccessToken != nil{
            // if the user is already logged in, go to the main screen
            uploadImageToFirebase()
            print("Already Logged in\(accountKit?.currentAccessToken?.accountID)")
            
            DispatchQueue.main.async(execute: {
                self.dismiss(animated: true, completion: nil)
            })
            
        }
        else{
            // Show the login screen
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // initialize Account Kit
        if accountKit == nil {
            accountKit = AKFAccountKit(responseType: .accessToken)
        }
        view.backgroundColor = .white
        // Do any additional setup after loading the view.
        view.addSubview(inputsContainerView)
        view.addSubview(continueButton)
        view.addSubview(cancelButton)
        view.addSubview(profileImageView)
        setupInputsContainerView()
        setupContinueButton()
        setupCancelButton()
        setupProfileImageView()
        
        
    }
    
    func setupProfileImageView() {
        // need x, y, width, height constraints
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
    }
    
    func setupInputsContainerView() {
        // need x, y, width, height constraints
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(nameSeparatorView)
//        inputsContainerView.addSubview(phoneTextField)
//        inputsContainerView.addSubview(phonepSeparatorView)
//
        
        // need x, y, width, height constraints -- nameTextField
        nameTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2).isActive = true
        
        
        
        // need x, y, width, height constraints -- nameSaparatorView
        nameSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        nameSeparatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
        
    }
    
    func setupContinueButton() {
        // need x, y, width, height constraints
        continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        continueButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -180).isActive = true
        continueButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupCancelButton() {
        cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cancelButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 12).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -180).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    

}
