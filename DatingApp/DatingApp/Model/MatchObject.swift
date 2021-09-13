//
//  MatchObject.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/1/21.
//

import Foundation

struct MatchObject {
    
    let id: String
    let memberIds: [String]
    let date: Date
    
    var dictionary: [String: Any] {
        return [kOBJECTID: id, kMEMBERIDS: memberIds, kDATE: date]
    }
    
    func saveToFireStore() {
        FirebaseReference(.Match).document(self.id).setData(self.dictionary)
    }
}
