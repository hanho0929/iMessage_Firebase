//
//  ViewController.swift
//  ChatApp
//
//  Created by hanho on 1/28/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import Firebase
import AccountKit

class MessagesController: UITableViewController, UISearchBarDelegate  {
    
    var accountKit: AKFAccountKit!
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    let cellId = "cellId"
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = UISearchBar.Style.prominent
        searchBar.placeholder = " Search..."
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        //searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set accountKit to the token
        self.accountKit = AKFAccountKit(responseType: AKFResponseType.accessToken)
        //navigationController?.navigationBar.prefersLargeTitles = true
        tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "SignOut", style: .plain, target: self, action: #selector(handleLogOut))

        let image = UIImage(named: "new_message")?.withRenderingMode(.alwaysOriginal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        tableView.allowsSelectionDuringEditing = true
        

        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    

    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = accountKit.currentAccessToken?.accountID else { return }
        
        let message = self.messages[indexPath.row]
        if let chatId = message.chatId() {
            let ref = Database.database().reference().child("user_messages").child(uid).child(chatId).removeValue { (error, ref) in
                if error != nil {
                    print("Failed to delete message:", error!)
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: chatId)
                self.attemptReloadOfTable()
            }
        }
        
        
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        checkAutoLogin()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return filtered.count
        }
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        if searchActive {
            cell.message = filtered[indexPath.item]
        } else {
            cell.message = message
        }

        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let chatId = message.chatId() else { return }
        let ref = Database.database().reference().child("users").child(chatId)
        ref.observe(.value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            let user = User(dictionary: dictionary)
            user.id = chatId
            self.showChatControllerForUser(user: user)
        }, withCancel: nil)


    }
    var timer: Timer?
    
    func observeUserMessage() {
        guard let uid = accountKit.currentAccessToken?.accountID else { return }
        let ref = Database.database().reference().child("user_messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            Database.database().reference().child("user_messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    private func fetchMessageWithMessageId(_ messageId: String) {
        let messagesReference = Database.database().reference().child("messages").child(messageId)
        messagesReference.observe(.value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary)
                if let chatId = message.chatId() {
                    self.messagesDictionary[chatId] = message
                }
                self.attemptReloadOfTable()
            }
        }, withCancel: nil)
    }
    
    private func attemptReloadOfTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadTable() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sorted(by: { (message1, message2) -> Bool in
            return message1.timestamp!.isLess(than: message2.timestamp!)
        })
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }


    func checkAutoLogin() {
        accountKit.requestAccount{ (account, error) in
            //  Check if user login
            if account == nil {
                self.perform(#selector(self.handleLogOut), with: nil, afterDelay: 0)
                return
            } else {
                let uid = account?.accountID
                
                Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        let user = User(dictionary: dictionary)
                        self.setupNavBarWithUser(user: user)
                    } else {
                        // Not register yet
                        self.perform(#selector(self.handleLogOut), with: nil, afterDelay: 0)
                    }
                })
            }
        }
    }
    
    
    func setupNavBarWithUser(user: User) {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        observeUserMessage()
//        let button = UIButton(type: .system)
//        button.setTitle(user.name, for: .normal)
//        self.navigationItem.titleView = button

        
        // add searchBar constraints
        self.view.addSubview(searchBar)
        let guide = self.view.safeAreaLayoutGuide
        searchBar.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        searchBar.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messageController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    @objc func showChatControllerForUser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.accountKit = accountKit
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc func handleLogOut() {
        accountKit.logOut()
        let loginController = HomeController()
        //loginController.mess
        present(loginController, animated: true, completion: nil)
    }




    var searchActive : Bool = false
    var filtered:[Message] = []
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }

    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == "" {
            searchActive = false
            // to dismiss keyboard
            view.endEditing(true)
            tableView.reloadData()
        }else{
            searchActive = true
            let lower = searchBar.text!.lowercased()
            filtered = messages.filter({ (message: Message) -> Bool in
                return (message.text?.lowercased().contains(lower))!
                //return (game.gameName?.lowercased().contains(lower))!
            })
            tableView.reloadData()
        }
    }
    
    

}

