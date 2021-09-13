//
//  LikeObject.swift
//  DatingApp
//
//  Created by 卢勇霏 on 5/31/21.
//

import Foundation

struct LikeObject {
    
    let id: String
    let userId: String
    let likedUserId: String
    let date: Date
    
    var dictionary: [String: Any] {
        return [kOBJECTID: id, kUSERID: userId, kLIKEDUSERID: likedUserId, kDATE: date]
    }
    
    func saveToFireStore() {
        FirebaseReference(.Like).document(self.id).setData(self.dictionary)
    }
}
