import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 0. GİZLİLİK AYARI (Privacy)
  Future<void> togglePrivacy(String uid, bool currentValue) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isPrivate': !currentValue,
      });
      print("✅ Gizlilik ayarı güncellendi: ${!currentValue}");
    } catch (e) {
      print("❌ togglePrivacy Error: $e");
      rethrow;
    }
  }

  // Arkadaşlık kontrolü (Kullanıcının istediği isimle)
  Future<bool> isFriend(String currentUserId, String targetUserId) async {
    return checkFriendStatus(currentUserId, targetUserId);
  }

  // 1. KULLANICI ARAMA (Search)
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      // Email ile arama
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: query)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return emailQuery.docs
            .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
            .toList();
      }

      // İsim ile arama (Prefix)
      final nameQuery = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      return nameQuery.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Search Error: $e");
      return [];
    }
  }

  // 2. PROFİL GETİR (Get Profile)
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print("Get Profile Error: $e");
      return null;
    }
  }

  // 3. ARKADAŞ EKLE (Direct Add - Sub-collection)
  Future<void> addFriendDirectly(String currentUserId, UserProfile targetUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendList')
          .doc(targetUser.uid)
          .set({
        'uid': targetUser.uid,
        'name': targetUser.name,
        'email': targetUser.email,
        'photoUrl': targetUser.photoUrl ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });
      print("✅ Arkadaş başarıyla eklendi: ${targetUser.name}");
    } catch (e) {
      print("❌ hATA (addFriendDirectly): $e");
      rethrow;
    }
  }

  // 4. ARKADAŞ SİL (Remove)
  Future<void> removeFriend(String currentUserId, String friendId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendList')
          .doc(friendId)
          .delete();
    } catch (e) {
      print("❌ Remove Error: $e");
      rethrow;
    }
  }

  // 5. ARKADAŞLIK İSTEĞİ KABUL ET (Accept) - ÇİFT TARAFLI
  Future<void> acceptFriendRequest(String currentUserId, String requesterId) async {
    try {
      // A. İstek gönderen kişinin bilgilerini çek
      final requesterDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('receivedRequests')
          .doc(requesterId)
          .get();
      
      // B. Kendi bilgilerimi çek
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (requesterDoc.exists && currentUserDoc.exists) {
        final requesterData = requesterDoc.data()!;
        final currentUserData = currentUserDoc.data()!;
        
        // C. Kendi friendList'ime EKLEME YAP
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friendList')
            .doc(requesterId)
            .set({
          'uid': requesterId,
          'name': requesterData['name'] ?? '',
          'email': requesterData['email'] ?? '',
          'photoUrl': requesterData['photoUrl'] ?? '',
          'addedAt': FieldValue.serverTimestamp(),
        });

        // D. KARŞI TARAFIN friendList'ine BENİ EKLE (ÇİFT TARAFLI)
        await _firestore
            .collection('users')
            .doc(requesterId)
            .collection('friendList')
            .doc(currentUserId)
            .set({
          'uid': currentUserId,
          'name': currentUserData['name'] ?? '',
          'email': currentUserData['email'] ?? '',
          'photoUrl': currentUserData['photoUrl'] ?? '',
          'addedAt': FieldValue.serverTimestamp(),
        });

        // E. receivedRequests koleksiyonundan sil
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('receivedRequests')
            .doc(requesterId)
            .delete();
        
        // F. Karşı tarafın sentRequests koleksiyonundan da sil
        await _firestore
            .collection('users')
            .doc(requesterId)
            .collection('sentRequests')
            .doc(currentUserId)
            .delete();
            
        print("✅ Arkadaşlık isteği kabul edildi (Çift taraflı)");
      }
    } catch (e) {
       print("❌ Accept Error: $e");
       rethrow;
    }
  }

  // 6. ARKADAŞLIK İSTEĞİNİ REDDET (Reject)
  Future<void> rejectFriendRequest(String currentUserId, String requesterId) async {
    try {
      // receivedRequests koleksiyonundan sil
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('receivedRequests')
          .doc(requesterId)
          .delete();
      
      // Karşı tarafın sentRequests koleksiyonundan da sil
      await _firestore
          .collection('users')
          .doc(requesterId)
          .collection('sentRequests')
          .doc(currentUserId)
          .delete();
          
      print("✅ Arkadaşlık isteği reddedildi");
    } catch (e) {
      print("❌ Reject Error: $e");
      rethrow;
    }
  }
  
  // 7. ARKADAŞLIK İSTEĞİ GÖNDER (Send Request - Sub-collection Yapısı)
  Future<void> sendFriendRequest(String currentUserId, UserProfile targetUser) async {
    try {
      // Önce mevcut kullanıcının bilgilerini alalım
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) {
        throw Exception("Kullanıcı bulunamadı");
      }
      
      final currentUserData = currentUserDoc.data()!;
      
      // ADIM A: Karşı tarafın receivedRequests koleksiyonuna BENİM bilgilerimi kaydet
      await _firestore
          .collection('users')
          .doc(targetUser.uid) // Hedef kullanıcı
          .collection('receivedRequests') // Gelen istekler
          .doc(currentUserId) // Benim ID'm (Tekrar eklemeyi önler)
          .set({
        'uid': currentUserId,
        'name': currentUserData['name'] ?? '',
        'email': currentUserData['email'] ?? '',
        'photoUrl': currentUserData['photoUrl'] ?? '',
        'sentAt': FieldValue.serverTimestamp(),
      });
      
      // ADIM B: Benim sentRequests koleksiyonuma HEDEFİN bilgilerini kaydet
      await _firestore
          .collection('users')
          .doc(currentUserId) // Ben
          .collection('sentRequests') // Gönderilen istekler
          .doc(targetUser.uid) // Hedefin ID'si (Tekrar eklemeyi önler)
          .set({
        'uid': targetUser.uid,
        'name': targetUser.name,
        'email': targetUser.email,
        'photoUrl': targetUser.photoUrl ?? '',
        'sentAt': FieldValue.serverTimestamp(),
      });
      
      print("✅ Arkadaşlık isteği gönderildi: ${targetUser.name}");
    } catch (e) {
      print("❌ İstek gönderme hatası: $e");
      rethrow;
    }
  }

  // 7B. GELEN İSTEKLERİ DİNLE (Stream)
  Stream<List<UserProfile>> getReceivedRequestsStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('receivedRequests')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return UserProfile(
              uid: data['uid'] ?? doc.id,
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              photoUrl: data['photoUrl'],
            );
          }).toList();
        });
  }

  // 7C. ARKADAŞ DURUMU KONTROL ET (Check if Friend)
  Future<bool> checkFriendStatus(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendList')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print("❌ Check Friend Status Error: $e");
      return false;
    }
  }

  // 7D. GÖNDERİLEN İSTEK DURUMU KONTROL ET (Check if Sent Request)
  Future<bool> checkSentRequestStatus(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sentRequests')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print("❌ Check Sent Request Status Error: $e");
      return false;
    }
  }

  // 7E. GELEN İSTEK DURUMU KONTROL ET (Check if Received Request)
  Future<bool> checkReceivedRequestStatus(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('receivedRequests')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print("❌ Check Received Request Status Error: $e");
      return false;
    }
  }


  // 8. ARKADAŞ LİSTESİ STREAM (Get Friends)
  Stream<List<UserProfile>> getFriendsStream(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friendList')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return UserProfile(
              uid: data['uid'] ?? doc.id,
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              photoUrl: data['photoUrl'],
            );
          }).toList();
        });
  }

  // 9. BİLDİRİM GÖNDER (Notification)
  Future<void> sendNotificationToFriends(String message) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Sub-collection'dan arkadaşları çek
      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friendList')
          .get();

      final batch = _firestore.batch();

      for (var doc in friendsSnapshot.docs) {
        final friendId = doc.id;
        final ref = _firestore.collection('users').doc(friendId).collection('notifications').doc();
        batch.set(ref, {
          'message': message,
          'senderId': currentUser.uid,
          'senderName': currentUser.displayName,
          'senderPhoto': currentUser.photoURL,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'item_bought'
        });
      }

      if (friendsSnapshot.docs.isNotEmpty) {
        await batch.commit();
        print("🔔 Bildirimler gönderildi.");
      }
    } catch (e) {
      print("❌ Notification Error: $e");
    }
  }
}