//
//  MKMessage.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/2/21.
//

import Foundation
import MessageKit

class MKMessage: NSObject, MessageType {
    
    var messageId: String
    var kind: MessageKind
    var sentDate: Date
    var incoming: Bool
    var mksender: MKSender
    var sender: SenderType { return mksender }
    var senderInitials: String
    
    var photoItem: PhotoMessage?
    var status: String
    
    init(message: Message) {
        self.messageId = message.id
        self.mksender = MKSender(senderId: message.senderId, displayName: message.senderName)
        self.status = message.status
        self.kind = MessageKind.text(message.message)
        self.senderInitials = message.senderInitials
        self.sentDate = message.sentDate
        self.incoming = FUser.currentId() != mksender.senderId
        
    }
    
}
