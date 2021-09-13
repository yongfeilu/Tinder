//
//  FirebaseListener.swift
//  DatingApp
//
//  Created by 卢勇霏 on 5/26/21.
//

import Foundation
import Firebase

class FirebaseListener {
    
    static let shared = FirebaseListener()
    
    private init() {}
    
    //Mark: FUser
    func downloadCurrentUserFromFirebase(userId: String, email: String) {
        
        FirebaseReference(.User).document(userId).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            if snapshot.exists {
                let user = FUser(_dictionary: snapshot.data() as! NSDictionary)
                user.saveUserLocally()
                user.getUserAvatarFromFirestore { (didSet) in
                }
            } else {
                //first login: save user info to FirebaseStore
                if let user = userDefaults.object(forKey: kCURRENTUSER) {
                    FUser(_dictionary: user as! NSDictionary).saveUserToFireStore()
                }
            }
        }
    }
    
    func downloadUsersFromFirebase(isInitialLoad: Bool, limit: Int, lastDocumentSnapshot: DocumentSnapshot?, completion: @escaping (_ users: [FUser], _ snapshot: DocumentSnapshot?) -> Void) {
        
        var query: Query!
        var users: [FUser] = []
        
        let ageFrom = Int(userDefaults.object(forKey: kAGEFROM) as? Float ?? 0.0)
        let ageTo = Int(userDefaults.object(forKey: kAGETO) as? Float ?? 90.0)
        
        if isInitialLoad {
            query = FirebaseReference(.User).whereField(kAGE, isGreaterThan: ageFrom - 1).whereField(kAGE, isLessThan: ageTo + 1).whereField(kISMALE, isEqualTo: isLookingForMale()).limit(to: limit)
            print("first \(limit) users loading")
            
        } else {
            
            if lastDocumentSnapshot != nil {
                query = FirebaseReference(.User).whereField(kAGE, isGreaterThan: ageFrom - 1).whereField(kAGE, isLessThan: ageTo + 1).whereField(kISMALE, isEqualTo: isLookingForMale()).limit(to: limit).start(afterDocument: lastDocumentSnapshot!)
                print("next \(limit) users loading")
            } else {
                print("last snapshot is nil")
            }
        }
        
        if query != nil {
            query.getDocuments { (snapShot, error) in
                guard let snapshot = snapShot else { return }
                if !snapshot.isEmpty {
                    for userData in snapshot.documents {
                        let userObject = userData.data() as NSDictionary
                        if !(FUser.currentUser()?.likedIdArray?.contains(userObject[kOBJECTID] as! String) ?? false ) && FUser.currentId() != userObject[kOBJECTID] as! String {
                            users.append(FUser(_dictionary: userObject))
                        }
                    }
                    completion(users, snapshot.documents.last!)
                } else {
                    print("no more users to fetch")
                    completion(users, nil)
                }
            }
        } else {
            print("no users to fetch")
            completion(users, nil)
        }
    }
    
    func downloadUsersFromFirebase(withIds: [String], completion: @escaping (_ users: [FUser]) -> Void) {
        
        var usersArray: [FUser] = []
        var counter = 0
        
        for userId in withIds {
            FirebaseReference(.User).document(userId).getDocument { (snapshot, error) in
                guard let snapshot = snapshot else { return }
                if snapshot.exists {
                    usersArray.append(FUser(_dictionary: snapshot.data()! as NSDictionary))
                    counter += 1
                    if counter == withIds.count {
                        completion(usersArray)
                    }
                } else {
                    completion(usersArray)
                }
            }
        }
    }
    
    //MARK:  - Likes
    func downloadUserLikes(completion: @escaping (_ likedUserIds: [String]) -> Void) {
        
        FirebaseReference(.Like).whereField(kLIKEDUSERID, isEqualTo: FUser.currentId()).getDocuments { (snapshot, error) in
            
            var allLikedIds: [String] = []
            guard let snapshot = snapshot else {
                completion(allLikedIds)
                return
            }
            
            if !snapshot.isEmpty {
                for likeDictionary in snapshot.documents {
                    allLikedIds.append(likeDictionary[kUSERID] as? String ?? "")
                }
                completion(allLikedIds)
            } else {
                print("No likes found")
                completion(allLikedIds)
            }
        }
    }
    
    
    func checkIfUserLikedUs(userId: String, completion: @escaping (_ didLike: Bool) -> Void) {
        
        FirebaseReference(.Like).whereField(kLIKEDUSERID, isEqualTo: FUser.currentId()).whereField(kUSERID, isEqualTo: userId).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            completion(!snapshot.isEmpty)
        }
    }
    
    //MARK:  - Match
    func downloadUserMatches(completion: @escaping (_ matchedUserIds: [String]) -> Void) {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        FirebaseReference(.Match).whereField(kMEMBERIDS, arrayContains: FUser.currentId()).whereField(kDATE, isGreaterThan: lastMonth).order(by: kDATE, descending: true).getDocuments { (snapshot, error) in
            var allMatchedIds: [String] = []
            guard let snapshot = snapshot else { return }
            if !snapshot.isEmpty {
                for matchDictionary in snapshot.documents {
                    allMatchedIds += matchDictionary[kMEMBERIDS] as? [String] ?? [""]
                }
                completion(removeCurrentUserIdFrom(userIds: allMatchedIds))
            } else {
                print("No Matches found")
                completion(allMatchedIds)
            }
        }
    }
    
    
    func saveMatch(userId: String) {
        let match = MatchObject(id: UUID().uuidString, memberIds: [FUser.currentId(), userId], date: Date())
        match.saveToFireStore()
    }
    
    //MARK:  - RecentChats
    func downloadRecentChatsFromFireStore(completion: @escaping (_ allRecents: [RecentChat]) -> Void) {
        FirebaseReference(.Recent).whereField(kSENDERID, isEqualTo: FUser.currentId()).addSnapshotListener { (querySnapshot, error) in
            var recentChats: [RecentChat] = []
            guard let snapshot = querySnapshot else { return }
            if !snapshot.isEmpty {
                for recentDocument in snapshot.documents {
                    if recentDocument[kLASTMESSAGE] as! String != "" && recentDocument[kCHATROOMID] != nil && recentDocument[kOBJECTID] != nil {
                        recentChats.append(RecentChat(recentDocument.data()))
                    }
                }
                recentChats.sort(by: { $0.date > $1.date})
                completion(recentChats)
            } else {
                completion(recentChats)
            }
        }
    }
    
    func updateRecents(chatRoomId: String, lastMessage: String) {
        
        FirebaseReference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            if !snapshot.isEmpty {
                for recent in snapshot.documents {
                    let recentChat = RecentChat(recent.data())
                    self.updateRecentItem(recent: recentChat, lastMessage: lastMessage)
                }
            }
        }
    }
    
    func updateRecentReceiverInFirebase(receiverId: String, receiverName: String?, avatarLink: String?) {
        FirebaseReference(.Recent).whereField(kRECEIVERID, isEqualTo: receiverId).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            if !snapshot.isEmpty {
                for recent in snapshot.documents {
                    let recentChat = RecentChat(recent.data())
                    if let newName = receiverName {
                        recentChat.receiverName = newName
                    }
                    if let newLink = avatarLink {
                        recentChat.avatarLink = newLink
                    }
                    FirebaseReference(.Recent).document(recentChat.objectId).updateData(recentChat.dictionary as! [String: Any]) { (error) in
                        print("update recent object when changing profile with ", error?.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func updateRecentItem(recent: RecentChat, lastMessage: String) {
        if recent.senderId != FUser.currentId() {
            recent.unreadCounter += 1
        }
        
        let values = [kLASTMESSAGE: lastMessage, kUNERADCOUNTER: recent.unreadCounter, kDATE: Date()] as [String: Any]
        FirebaseReference(.Recent).document(recent.objectId).updateData(values) { (error) in
            print("error updating recent ", error)
        }
    }
    
    func resetRecentCounter(chatRoomId: String) {
        FirebaseReference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).whereField(kSENDERID, isEqualTo: FUser.currentId()).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            if !snapshot.isEmpty {
                if let recentData = snapshot.documents.first?.data() {
                    let recent = RecentChat(recentData)
                    self.clearUnreadCounter(recent: recent)
                }
            }
        }
    }
    
    func clearUnreadCounter(recent: RecentChat) {
        let values = [kUNERADCOUNTER : 0] as [String : Any]
        FirebaseReference(.Recent).document(recent.objectId).updateData(values) { (error) in
            print("Reset recent counter with ", error)
        }
    }
}
