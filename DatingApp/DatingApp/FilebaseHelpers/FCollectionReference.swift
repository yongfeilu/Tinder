//
//  FCollectionReference.swift
//  DatingApp
//
//  Created by 卢勇霏 on 5/26/21.
//

import Foundation
import FirebaseFirestore

enum FCollectionReference: String {
    case User
    case Like
    case Match
    case Recent
    case Messages
    case Typing
}

func FirebaseReference(_ collectionReference: FCollectionReference) -> CollectionReference {
    
    return Firestore.firestore().collection(collectionReference.rawValue)
}
