//
//  CustomTabBarController.swift
//  ChatApp
//
//  Created by hanho on 1/30/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit

class CustomTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let messagesController = MessagesController()
        let recentMessageNavController = UINavigationController(rootViewController: messagesController)
        recentMessageNavController.tabBarItem.title = "Chat"
        recentMessageNavController.tabBarItem.image = UIImage(named: "groups")
        
        let settingController = UINavigationController(rootViewController: SettingController())
        settingController.navigationItem.title = "Setting"
        settingController.tabBarItem.title = "Setting"
        settingController.tabBarItem.image = UIImage(named: "settings")
        
        viewControllers = [recentMessageNavController, settingController]
        
    }
}


class CustomNavigationBar: UINavigationBar {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let newSize :CGSize = CGSize(width: self.frame.size.width, height: 54)
        return newSize
    }
}
