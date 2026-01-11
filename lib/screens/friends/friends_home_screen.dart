import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/friend_service.dart';
import '../../models/user_profile.dart';
import 'friend_search_screen.dart';
import 'friend_requests_screen.dart';
import 'friend_profile_screen.dart'; // Profil sayfası için import

class FriendsHomeScreen extends StatefulWidget {
  const FriendsHomeScreen({super.key});

  @override
  State<FriendsHomeScreen> createState() => _FriendsHomeScreenState();
}

class _FriendsHomeScreenState extends State<FriendsHomeScreen> {
  int _selectedIndex = 0; // 0: Arkadaşlarım, 1: İstekler
  
  final FriendService _friendService = FriendService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- RENK PALETİ ---
  // Arkadaşlarım sekmesi için Pembe
  final Color _tabPink = const Color(0xFFF472B6); 
  // İstekler sekmesi için MOR (İsteğine göre güncellendi)
  final Color _tabPurple = const Color(0xFF9333EA); 
  
  final Color _bgLight = const Color(0xFFF3E8FF); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Arkadaşlar",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_rounded, color: _tabPink, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendSearchScreen()));
            },
          )
        ],
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _friendService.getReceivedRequestsStream(_currentUserId),
        builder: (context, snapshot) {
          int requestCount = 0;
          if (snapshot.hasData) {
            requestCount = snapshot.data!.length;
          }

          return Column(
            children: [
               // Üstteki Geçiş Butonları (Toggle)
               _buildToggleSwitch(requestCount),
               
               // Alt Kısımdaki Liste Alanı
               Expanded(
                 child: Container(
                   decoration: BoxDecoration(
                     // ignore: deprecated_member_use
                     color: _bgLight.withOpacity(0.5),
                     borderRadius: const BorderRadius.only(
                       topLeft: Radius.circular(30),
                       topRight: Radius.circular(30),
                     ),
                   ),
                   child: _selectedIndex == 0 
                     ? _buildFriendsList() // Arkadaşlar Listesi
                     : const FriendRequestsScreen(), // İstekler Ekranı
                 ),
               ),
            ],
          );
        }
      ),
    );
  }

  // --- ÖZELLEŞTİRİLMİŞ TOGGLE SWITCH ---
  Widget _buildToggleSwitch(int requestCount) {
    // Şu anki aktif renk: Seçim 0 ise Pembe, 1 ise MOR
    Color activeColor = _selectedIndex == 0 ? _tabPink : _tabPurple;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // SOL BUTON: ARKADAŞLARIM
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? _tabPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _selectedIndex == 0 
                    // ignore: deprecated_member_use
                    ? [BoxShadow(color: _tabPink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                    : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Arkadaşlarım",
                  style: TextStyle(
                    color: _selectedIndex == 0 ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          
          // SAĞ BUTON: İSTEKLER (MOR OLACAK)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: Container(
                decoration: BoxDecoration(
                  // Eğer seçiliyse MOR (_tabPurple) yap
                  color: _selectedIndex == 1 ? _tabPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _selectedIndex == 1 
                    // ignore: deprecated_member_use
                    ? [BoxShadow(color: _tabPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                    : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "İstekler",
                      style: TextStyle(
                        color: _selectedIndex == 1 ? Colors.white : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (requestCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedIndex == 1 ? Colors.white : _tabPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$requestCount",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedIndex == 1 ? _tabPurple : Colors.white,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<UserProfile>>(
      stream: _friendService.getFriendsStream(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _tabPink));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final friends = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Alttan boşluk bıraktık
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // --- PROFİLE GİTME ÖZELLİĞİ ---
                onTap: () {
                   Navigator.push(
                     context, 
                     MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend))
                   );
                },
                leading: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ignore: deprecated_member_use
                    border: Border.all(color: _tabPink.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    // ignore: deprecated_member_use
                    backgroundColor: _tabPink.withOpacity(0.1),
                    backgroundImage: friend.photoUrl != null && friend.photoUrl!.isNotEmpty 
                        ? NetworkImage(friend.photoUrl!) 
                        : null,
                    child: (friend.photoUrl == null || friend.photoUrl!.isEmpty)
                        ? Text(friend.name[0].toUpperCase(), style: TextStyle(color: _tabPink, fontWeight: FontWeight.bold, fontSize: 20))
                        : null,
                  ),
                ),
                title: Text(
                  friend.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  friend.email,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: _tabPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.chevron_right, color: _tabPink, size: 20),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Henüz arkadaşın yok",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}