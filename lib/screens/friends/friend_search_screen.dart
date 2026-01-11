import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../services/friend_service.dart';
import 'friend_profile_screen.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  // Colors
  final Color _bgStart = const Color(0xFFF3E8FF);
  final Color _accentPurple = const Color(0xFFC084FC);
  final Color _accentPink = const Color(0xFFF472B6);

  List<UserProfile> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  void _onSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _friendService.searchUsers(_searchController.text.trim());
      // Filter out self
      final filtered = results.where((u) => u.uid != _currentUserId).toList();
      setState(() {
        _searchResults = filtered;
      });
    } catch (e) {
      setState(() {
        // More user friendly error handling
        String errorStr = e.toString();
        debugPrint("SEARCH ERROR: $errorStr"); // Log to console
        if (errorStr.contains('permission-denied')) {
          _errorMessage = "Arama yapmak için yetkiniz yok veya kurallar eksik.";
        } else {
          _errorMessage = "Arama sırasında bir hata oluştu: ${e.toString()}";
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ARKADAŞLIK İSTEĞİ GÖNDER
  Future<void> _sendFriendRequest(UserProfile targetUser) async {
    try {
      print("🚀 İstek gönderilmeye başlandı..."); 
      
      // Yeni 'İstek' mantığı için sendFriendRequest kullanıyoruz
      await _friendService.sendFriendRequest(_currentUserId, targetUser); 
      
      print("✅ İstek başarıyla gönderildi (Kod hatasız çalıştı).");
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${targetUser.name} kişisine istek gönderildi!"), backgroundColor: Colors.green),
      );
      
      // Listeyi yenile
      setState(() {});

    } catch (e) {
      // İşte hatayı burada yakalayacağız
      print("🔥 HATA OLUŞTU: $e");
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Arkadaş Bul", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.black87, onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart.withOpacity(0.5), Colors.white],
            stops: const [0.0, 0.4]
          )
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))
                  ]
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Kullanıcı adı veya isim ara...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search_rounded, color: _accentPurple),
                    suffixIcon: IconButton(
                       icon: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: _accentPink, borderRadius: BorderRadius.circular(8)),
                         child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)
                       ),
                       onPressed: _onSearch,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
            ),
            
            if (_isLoading)
              LinearProgressIndicator(color: _accentPurple, backgroundColor: _bgStart),
            
            if (_errorMessage != null)
               Container(
                 margin: const EdgeInsets.all(16.0),
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.orange.shade50,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.orange.shade200)
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                     const SizedBox(width: 12),
                     Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.orange.shade800))),
                   ],
                 ),
               ),
            
            if (!_isLoading && _searchResults.isEmpty && _searchController.text.isNotEmpty && _errorMessage == null)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("Kullanıcı bulunamadı", style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Lütfen ismi kontrol edin veya\ndoğru e-posta adresini girin.", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              )
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    
                    // Sub-collection'lardan durumu kontrol et
                    return FutureBuilder<Map<String, bool>>(
                      future: Future.wait([
                        _friendService.checkFriendStatus(_currentUserId, user.uid),
                        _friendService.checkSentRequestStatus(_currentUserId, user.uid),
                        _friendService.checkReceivedRequestStatus(_currentUserId, user.uid),
                      ]).then((results) => {
                        'isFriend': results[0],
                        'isRequestSent': results[1],
                        'hasRequestFrom': results[2],
                      }),
                      builder: (context, snapshot) {
                        // Yükleniyor durumu
                        if (!snapshot.hasData) {
                          return Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: _accentPurple.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                              ]
                            ),
                            child: Center(child: CircularProgressIndicator(color: _accentPurple, strokeWidth: 2)),
                          );
                        }

                        final statusMap = snapshot.data!;
                        final isFriend = statusMap['isFriend'] ?? false;
                        final isRequestSent = statusMap['isRequestSent'] ?? false;
                        final hasRequestFrom = statusMap['hasRequestFrom'] ?? false;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: _accentPurple.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                 // Navigate to friend profile
                                 Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: user)));
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: _bgStart,
                                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                                      child: user.photoUrl == null 
                                        ? Text(user.name.substring(0, 1).toUpperCase(), style: TextStyle(color: _accentPurple, fontWeight: FontWeight.bold, fontSize: 20)) 
                                        : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name, 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                                          ),
                                          Text(
                                            user.email, 
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isFriend)
                                      const Chip(
                                        label: Text("Arkadaşsınız", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                        backgroundColor: Color(0xFFDCFCE7),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )
                                    else if (hasRequestFrom)
                                       Chip(
                                        label: const Text("İstek Attı", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.orange.shade50,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )
                                    else if (isRequestSent)
                                      const Chip(
                                        label: Text("İstek yollandı", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                        backgroundColor: Color(0xFFF3F4F6),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: () => _sendFriendRequest(user),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _accentPurple,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                          minimumSize: const Size(60, 36)
                                        ),
                                        child: const Text("Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

          ],
        ),
      ),
    );
  }
}
