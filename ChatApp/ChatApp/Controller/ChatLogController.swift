//
//  ChatLogController.swift
//  ChatApp
//
//  Created by hanho on 2/2/19.
//  Copyright © 2019 hanho. All rights reserved.
//

import UIKit
import Firebase
import AccountKit
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Variable
    var accountKit: AKFAccountKit!
    var containerViewBottomAnchor: NSLayoutConstraint?
    var messages = [Message]()
    let cellId = "cellId"
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    

    lazy var inputContainerView: ChatInputContainerView = {
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.keyboardDismissMode = .interactive
        //setupDimissKeyboard()
        setupKeyboardObservers()
    }
    
    
    
    func observeMessages() {
        guard let uid = accountKit?.currentAccessToken?.accountID, let toId = user?.id else { return }
        let userMessagesRef = Database.database().reference().child("user_messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            
            messagesRef.observe(.value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
                let message = Message(dictionary: dictionary)
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    
                    self.collectionView?.scrollToItem(at: indexPath , at: .bottom, animated: true)
                    //self.collectionView?.scrollToLast()
                    
                }
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // whenever user touch the chat screen, keyboard disappear
        inputContainerView.inputTextField.resignFirstResponder()
    }
    
    @objc func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            handleVideo(from: videoUrl)
        } else {
            handleImage(from: info)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideo(from url: URL) {
        let filename = UUID().uuidString + ".mov"
        let ref = Storage.storage().reference().child("message_movies").child(filename)
        let uploadTask = ref.putFile(from: url, metadata: nil) { (metadata, err) in
            if let err = err {
                print("Fail to upload the video", err)
                return
            }
            
            ref.downloadURL(completion: { (downloadUrl, error) in
                if let err = err {
                    print("Fail to get download url", err)
                    return
                }
                
                guard let downloadUrl = downloadUrl else { return }
                if let thumbnailImage = self.thumbnailImage(from: url) {
                    self.uploadToFirebase(thumbnailImage, completion: { (imageUrl) in
                        
                    let properties  = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": downloadUrl.absoluteString] as [String: AnyObject]
                        self.sendMessageWithProperties(with: properties)
                    })
                }
                
            })
        }
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImage(from video: URL) -> UIImage? {
        let asset = AVAsset(url: video)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
    private func handleImage(from info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebase(selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl, image: selectedImage)
            })
        }
        
    }
    
    private func uploadToFirebase(_ image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        if let uploadData = image.jpegData(compressionQuality: 0.2) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Failed to upload image:", error!)
                    return
                }
                ref.downloadURL(completion: { (url, err) in
                    if let err = err {
                        print(err)
                        return
                    }
                    completion(url?.absoluteString ?? "")
                })
                
            })
        }
    }

    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    // Zooming logic
    func performZoomInForImageView(imageView: UIImageView) {
        
        self.startingImageView = imageView
        self.startingImageView?.isHidden = true
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.image = imageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                
                zoomingImageView.center = keyWindow.center
            }) { (completed: Bool) in
                //
            }
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            // animate back to controller
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }) { (completed: Bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        let message = messages[indexPath.item]
        
        
        cell.chatLogController = self
        
        cell.message = message
        
        cell.textView.text = message.text
        
        setUpCell(cell: cell, message: message)
        if let text = message.text {
            // a text message
            cell.bubbleWidthAnchor?.constant = estimateFrame(from: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            // fall in here if its an image message
            //cell.textView.text = "Sending a photo"
            cell.textView.isHidden = true
            cell.bubbleWidthAnchor?.constant = 200
        }
    
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    private func setUpCell(cell: ChatMessageCell, message: Message) {
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrl(urlString: profileImageUrl)
        }
        
        if message.fromId == accountKit?.currentAccessToken?.accountID {
            // outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        } else {
            // incoming gray
            cell.bubbleView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrl(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // inputContainerView.inputTextField.resignFirstResponder()
        // avoid memory leak
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Send Button Pressed
    @objc func handleSend() {
        let properties = ["text": inputContainerView.inputTextField.text!] as [String: AnyObject]
        sendMessageWithProperties(with: properties)
    }
    
    private func sendMessageWithImageUrl(_ imageUrl: String, image: UIImage) {
        let properties = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as  [String: AnyObject]
        sendMessageWithProperties(with: properties)
    }
    
    private func sendMessageWithProperties(with properties: [String: AnyObject]) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        self.accountKit = AKFAccountKit(responseType: AKFResponseType.accessToken)
        
        let toId = user!.id!
        let fromId = accountKit.currentAccessToken!.accountID
        let timestamp = NSDate().timeIntervalSince1970
        
        var values = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : AnyObject]
        
        // append properties dictionary $0 key, $1 value
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error)
                return
            }
            
            
            self.inputContainerView.inputTextField.text = nil
            
            guard let messageId = childRef.key else { return }
            
            let userMessageRef = Database.database().reference().child("user_messages").child(fromId).child(toId).child(messageId)
            userMessageRef.setValue(1)
            let recipientUserMessagesRef = Database.database().reference().child("user_messages").child(toId).child(fromId).child(messageId)
            recipientUserMessagesRef.setValue(1)
        }
    }
}

extension ChatLogController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        // get height
        let message = messages[indexPath.item]
        
        
        if let text = message.text {
            height = estimateFrame(from: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue{
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
    
    private func estimateFrame(from text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 16)]), context: nil)
    }
}

fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}


