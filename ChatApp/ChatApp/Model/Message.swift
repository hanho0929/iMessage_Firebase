//
//  Message.swift
//  ChatApp
//
//  Created by hanho on 1/31/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import AccountKit

class Message: NSObject {
    var accountKit: AKFAccountKit?
    var fromId: String?
    var text: String?
    var timestamp: Double?
    var toId: String?
    
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    
    init(dictionary: [String: AnyObject]) {
        self.fromId = dictionary["fromId"] as? String
        self.text = dictionary["text"] as? String
        self.timestamp = dictionary["timestamp"] as? Double
        self.toId = dictionary["toId"] as? String
        self.imageUrl = dictionary["imageUrl"] as? String
        self.imageWidth = dictionary["imageWidth"] as? NSNumber
        self.imageHeight = dictionary["imageHeight"] as? NSNumber
        self.accountKit = AKFAccountKit(responseType: .accessToken)
    }
    
    func chatId() -> String? {
        return fromId == accountKit?.currentAccessToken?.accountID ? toId : fromId
    }
}
