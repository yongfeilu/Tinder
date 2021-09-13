//
//  IncomingMessage.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/2/21.
//

import Foundation
import MessageKit
import Firebase

class IncomingMessage {
    var messageCollectionView: MessagesViewController
    
    init(collectionView_: MessagesViewController) {
        messageCollectionView = collectionView_
    }
    
    func createMessage(messageDictionary: [String: Any]) -> MKMessage? {
        let message = Message(dictionary: messageDictionary)
        let mkMessage = MKMessage(message: message)
        if message.type == kPICTURE {
            let photoItem = PhotoMessage(path: message.mediaURL)
            mkMessage.photoItem = photoItem
            mkMessage.kind = MessageKind.photo(photoItem)
            
            FileStorage.downloadImage(imageUrl: messageDictionary[kMEDIAURL] as? String ?? "") { (image) in
                mkMessage.photoItem?.image = image
                DispatchQueue.main.async {
                    self.messageCollectionView.messagesCollectionView.reloadData()
                }
            }
        }
        return mkMessage
    }
}
