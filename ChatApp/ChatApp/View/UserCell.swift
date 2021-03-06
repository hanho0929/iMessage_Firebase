//
//  UserCell.swift
//  ChatApp
//
//  Created by hanho on 2/1/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import Firebase
import AccountKit

class UserCell: UITableViewCell {
    
    var accountKit: AKFAccountKit!
    
    var message: Message? {
        didSet {
            setUpNameAndProfile()
            
            detailTextLabel?.text = message?.text
            
            if let seconds = message?.timestamp {
                let timestampDate = NSDate(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()

                dateFormatter.dateFormat = "hh:mm:ss a"
                timeLabel.text = dateFormatter.string(for: timestampDate)
            }
            
        }
    }
    
    private func setUpNameAndProfile() {

        if let id = message?.chatId() {
            let ref = Database.database().reference().child("users").child(id)
            ref.observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    self.textLabel?.text = dictionary["name"] as? String
                    if let profilImageUrl = dictionary["profileImageUrl"] as? String{
                        self.profileImageView.loadImageUsingCacheWithUrl(urlString: profilImageUrl)
                    }
                    
                }
                print(snapshot)
            }, withCancel: nil)
        }
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel?.frame = CGRect(x: 56, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 56, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        //imageView.image = UIImage(named: "dog")
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        //label.text = "HH:MM:SS"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        self.accountKit = AKFAccountKit(responseType: AKFResponseType.accessToken)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        setupProfileImageViewConstraint()
        setupTimeLabelConstraint()
    }
    
    func setupProfileImageViewConstraint() {
        // need x, y, width, height
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    func setupTimeLabelConstraint() {
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!).isActive = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

