//
//  Extension.swift
//  ChatApp
//
//  Created by hanho on 1/31/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import AccountKit

let imageCache = NSCache<AnyObject, AnyObject>()


extension UIImageView {
    func loadImageUsingCacheWithUrl(urlString: String) {
        let url = URL(string: urlString)
        // check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage{
            self.image = cachedImage
            return
        }
        
        
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            // download hit an error so lets return
            if error != nil {
                print(error)
                return
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                }
                
            }
            }.resume()
    }
}


extension AKFViewControllerDelegate {
    
    func prepareLoginViewController(loginViewController: AKFViewController) {
        loginViewController.delegate = self
        let theme:AKFTheme = AKFTheme.default()
        loginViewController.setTheme(theme)
    }
}
//
//extension Date {
//    func toMillis() -> Int64! {
//        return Int64(self.timeIntervalSince1970 * 1000)
//    }
//}

