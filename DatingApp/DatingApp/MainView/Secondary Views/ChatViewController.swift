//
//  ChatViewController.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/2/21.
//

import Foundation
import MessageKit
import InputBarAccessoryView
import Firebase
import Gallery

class ChatViewController: MessagesViewController {
    //MARK:  - Vars
    private var chatId = ""
    private var recipientId = ""
    private var recipientName = ""
    
    let refreshController = UIRefreshControl()
    let currentUser = MKSender(senderId: FUser.currentId(), displayName: FUser.currentUser()!.username)
    
    private var mkmessages: [MKMessage] = []
    var loadedMessageDictionaries: [Dictionary<String, Any>] = []
    
    var gallery: GalleryController!
    
    var initialLoadCompleted = false
    var displayingMessagesCount = 0
    
    var maxMessageNumber = 0
    var minMessageNumber = 0
    var loadOld = false
    
    var typingCounter = 0
    //Listeners
    var newChatListener: ListenerRegistration?
    var typingListener: ListenerRegistration?
    var updateChatListener: ListenerRegistration?
    
    //MARK:  - Inits
    init(chatId: String, recipientId: String, recipientName: String) {
        super.init(nibName: nil, bundle: nil)
        
        self.chatId = chatId
        self.recipientId = recipientId
        self.recipientName = recipientName
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //MARK:  - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
        setChatTitle()
        createTypingObserver()
        configureLeftButton()
        configureMessageCollectionView()
        configureMessageInputBar()
        listenForReadStatusChange()
        downloadChats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseListener.shared.resetRecentCounter(chatRoomId: chatId)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeListener()
        FirebaseListener.shared.resetRecentCounter(chatRoomId: chatId)
    }
    
    //MARK:  - Config
    private func configureLeftButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(self.backButtonPressed))
    }
    
    private func configureMessageInputBar() {
        messageInputBar.delegate = self
        let button = InputBarButtonItem()
        button.image = UIImage(named: "attach")
        button.setSize(CGSize(width: 30, height: 30), animated: false)
        button.onTouchUpInside { (item) in
            self.actionAttachMessage()
        }
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        
        messageInputBar.inputTextView.isImagePasteEnabled = false
        messageInputBar.backgroundView.backgroundColor = .systemBackground
        messageInputBar.inputTextView.backgroundColor = .systemBackground
    }
    
    private func  configureMessageCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        
        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        messagesCollectionView.refreshControl =  refreshController
    }
    
    private func setChatTitle() {
        self.title = recipientName
    }
    
    //MARK:  - Actions
    @objc func backButtonPressed() {
        
        FirebaseListener.shared.resetRecentCounter(chatRoomId: chatId)
        removeListener()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func actionAttachMessage() {
        messageInputBar.inputTextView.resignFirstResponder()
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhoto = UIAlertAction(title: "Camera", style: .default) { (alert) in
            self.showImageGalleryFor(camera: true)
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (alert) in
            self.showImageGalleryFor(camera: false)
            
        }
        let cancelAction = UIAlertAction(title: "Cacel", style: .cancel, handler: nil)
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    private func messageSend(text: String?, photo: UIImage?) {
        OutgoingMessage.send(chatId: chatId, text: text, photo: photo, memberIds: [FUser.currentId(), recipientId])
    }
    
    //MARK:  - Download chats
    private func downloadChats() {
        FirebaseReference(.Messages).document(FUser.currentId()).collection(chatId).limit(to: 15).order(by: kDATE, descending: true).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                self.initialLoadCompleted = true
                // listen for new chats
                return
            }
            
            self.loadedMessageDictionaries = ((self.dictionaryArrayFromSnapshot(snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [Dictionary<String, Any>]
            //insert messages to chatroom
            self.insertMessages()
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToBottom()
            self.initialLoadCompleted = true
 
            // download old chats
            self.getOldMessagesInBackground()
            // listen for new chats
            self.listenForNewChats()
        }
    }
    
    private func listenForNewChats() {
        newChatListener = FirebaseReference(.Messages).document(FUser.currentId()).collection(chatId).whereField(kDATE, isGreaterThan: lastMessageDate()).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else { return }
            if !snapshot.isEmpty {
                for change in snapshot.documentChanges {
                    if change.type == .added {
                        self.insertMessage(change.document.data())
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
            }
        })
    }
    
    private func getOldMessagesInBackground() {
        if loadedMessageDictionaries.count > kNUMBEROFMESSAGES {
            FirebaseReference(.Messages).document(FUser.currentId()).collection(chatId).whereField(kDATE, isLessThan: firstMessageDate()).getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else { return }
                self.loadedMessageDictionaries = ((self.dictionaryArrayFromSnapshot(snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [Dictionary<String, Any>] + self.loadedMessageDictionaries
                self.messagesCollectionView.reloadData()
                
                self.maxMessageNumber = self.loadedMessageDictionaries.count - self.displayingMessagesCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    private func listenForReadStatusChange() {
        updateChatListener = FirebaseReference(.Messages).document(FUser.currentId()).collection(chatId).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else { return }
            if !snapshot.isEmpty {
                snapshot.documentChanges.forEach { (change) in
                    if change.type == .modified {
                        self.updateMessage(change.document.data())
                    }
                }
            }
        })
    }
    
    private func updateMessage(_ messageDictionary: Dictionary<String, Any>) {
        for index in 0 ..< mkmessages.count {
            let tempMessage = mkmessages[index]
            if messageDictionary[kOBJECTID] as! String == tempMessage.messageId {
                mkmessages[index].status = messageDictionary[kSTATUS] as? String ?? kSENT
                if mkmessages[index].status == kREAD {
                    self.messagesCollectionView.reloadData()
                }
            }
        }
    }
    
    //MARK:  - Insert Messages
    private func insertMessages() {
        maxMessageNumber = loadedMessageDictionaries.count - displayingMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        for i in minMessageNumber ..< maxMessageNumber {
            let messageDictionary = loadedMessageDictionaries[i]
            insertMessage(messageDictionary)
            displayingMessagesCount += 1
        }
    }
    
    private func insertMessage(_ messageDictionary: Dictionary<String, Any>) {
        
        markMessageAsRead(messageDictionary)
        let incoming = IncomingMessage(collectionView_: self)
        self.mkmessages.append(incoming.createMessage(messageDictionary: messageDictionary)!)
    }
    
    private func insertOldMessage(_ messageDictionary: Dictionary<String, Any>) {
        let incoming = IncomingMessage(collectionView_: self)
        self.mkmessages.insert(incoming.createMessage(messageDictionary: messageDictionary)!, at: 0)
    }
    
    private func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        if loadOld {
            maxMessageNumber = minNumber - 1
            minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        for i in (minMessageNumber ... maxMessageNumber).reversed() {
            let messageDictionary = loadedMessageDictionaries[i]
            insertOldMessage(messageDictionary)
            displayingMessagesCount += 1
        }
        loadOld = true
    }
    
    private func markMessageAsRead(_ messageDictionary: Dictionary<String, Any>) {
        
        if messageDictionary[kSENDERID] as! String != FUser.currentId() {
            OutgoingMessage.updateMessage(withId: messageDictionary[kOBJECTID] as! String, chatRoomId: chatId, memberIds: [FUser.currentId(), recipientId])
        }
    }
    
    private func removeListener() {
        if newChatListener != nil {
            newChatListener!.remove()
        }
        if typingListener != nil {
            typingListener!.remove()
        }
        if updateChatListener != nil {
            updateChatListener!.remove()
        }
    }
    
    //MARK:  - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if refreshController.isRefreshing {
            if displayingMessagesCount < loadedMessageDictionaries.count {
                self.loadMoreMessages(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
                messagesCollectionView.reloadDataAndKeepOffset()
            }
            refreshController.endRefreshing()
        }
    }
    
    //MARK:  - Helpers
    private func dictionaryArrayFromSnapshot(_ snapshots: [DocumentSnapshot]) -> [Dictionary<String, Any>] {
        var allMessages: [Dictionary<String, Any>] = []
        for snapshot in snapshots {
            allMessages.append(snapshot.data()!)
        }
        return allMessages
    }
    
    private func lastMessageDate() -> Date {
        let lastMessageDate = (loadedMessageDictionaries.last?[kDATE] as? Timestamp)?.dateValue() ?? Date()
        return Calendar.current.date(byAdding: .second, value: 1, to: lastMessageDate) ?? lastMessageDate
    }
    
    private func firstMessageDate() -> Date {
        let firstMessageDate = (loadedMessageDictionaries.first?[kDATE] as? Timestamp)?.dateValue() ?? Date()
        return Calendar.current.date(byAdding: .second, value: -1, to: firstMessageDate) ?? firstMessageDate
    }
    
    //MARK:  - Typing indicator
    private func createTypingObserver() {
        TypingListener.shared.createTypingObserver(chatRoomId: chatId) { (isTyping) in
            self.setTypingIndicatorViewHidden(!isTyping, animated: false, whilePerforming: nil) { [weak self] success in
                if success, self?.isLastSectionVisible() == true {
                    self?.messagesCollectionView.scrollToBottom(animated: true)
                }
            }
        }
    }
    
    private func typingIndicatorUpdate() {
        typingCounter += 1
        TypingListener.saveTypingCounter(typing: true, chatRoomId: chatId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.typingCounterStop()
        }
    }
    private func typingCounterStop() {
        typingCounter -= 1
        if typingCounter == 0 {
            TypingListener.saveTypingCounter(typing: false, chatRoomId: chatId)
        }
    }
    
    func isLastSectionVisible() -> Bool {
        guard !mkmessages.isEmpty else {
            return false
        }
        let lastIndexPath = IndexPath(item: 0, section: mkmessages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    //MARK:  - Gallery
    private func showImageGalleryFor(camera: Bool) {
        self.gallery = GalleryController()
        self.gallery.delegate = self
        Config.tabsToShow = camera ? [.cameraTab] : [.imageTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .imageTab
        self.present(gallery, animated: true, completion: nil)
    }
    
}

extension ChatViewController: MessagesDataSource {
    
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return mkmessages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mkmessages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            let showLoadMore = (indexPath.section == 0) && loadedMessageDictionaries.count > displayingMessagesCount
            
            let text = showLoadMore ? "Pull to load more" : MessageKitDateFormatter.shared.string(from: message.sentDate)
            let font = showLoadMore ? UIFont.boldSystemFont(ofSize: 15) : UIFont.boldSystemFont(ofSize: 10)
            let color = showLoadMore ? UIColor.systemBlue : UIColor.darkGray
            return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
        }
        return nil
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isFromCurrentSender(message: message) {
            let message = mkmessages[indexPath.section]
            let status = indexPath.section == mkmessages.count - 1 ? message.status : ""
            return NSAttributedString(string: status, attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
        }
        return nil
    }
}



extension ChatViewController: MessagesLayoutDelegate {
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section % 3 == 0 {
            if (indexPath.section == 0) && loadedMessageDictionaries.count > displayingMessagesCount {
                return 40
            }
            return 18
        }
        return 0
    }
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isFromCurrentSender(message: message) ? 17 : 0
    }
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) {
        avatarView.set(avatar: Avatar(initials: mkmessages[indexPath.section].senderInitials))
    }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        print("tap on image message")
    }
}

extension ChatViewController: MessagesDisplayDelegate {
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        switch detector {
        case .hashtag, .mention:
            return [.foregroundColor: UIColor.blue]
        default:
            return MessageLabel.defaultAttributes
        }
    }
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? MessageDefaults.bubbleColorOutgoing : MessageDefaults.bubbleColorIncoming
    }
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        if text != "" {
            typingIndicatorUpdate()
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        for component in inputBar.inputTextView.components {
            if let text = component as? String {
                //send message
                messageSend(text: text, photo: nil)
            }
        }
        messageInputBar.inputTextView.text = ""
        messageInputBar.invalidatePlugins()
        messageInputBar.inputTextView.resignFirstResponder()
    }
}

extension ChatViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        if images.count > 0 {
            images.first!.resolve { (image) in
                self.messageSend(text: nil, photo: image)
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
        
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}
