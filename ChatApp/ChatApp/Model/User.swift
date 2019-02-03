//
//  User.swift
//  ChatApp
//
//  Created by hanho on 1/30/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit



class User: NSObject {
    var id : String?
    var name: String?
    var phoneNumber: String?
    var profileImageUrl: String?
    
    init(dictionary: [String: AnyObject]) {
        self.name = dictionary["name"] as? String
        self.phoneNumber = dictionary["phoneNumber"] as? String
        self.profileImageUrl = dictionary["profileImageUrl"] as? String
    }
}
