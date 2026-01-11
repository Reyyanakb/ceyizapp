import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/friend_service.dart';
import '../../models/user_profile.dart';
import '../../main.dart'; // ChecklistItem, AppCategory


class FriendProfileScreen extends StatefulWidget {
  final UserProfile friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  bool isLoading = true;
  Map<String, List<ChecklistItem>> checklistData = {};
  double totalSpent = 0;
  int totalCompleted = 0;
  bool isPrivateAccount = false;
  bool isFriends = false;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    try {
      // 1. Hedef kullanıcının profilini çek (Gizlilik ayarı için)
      final friendDoc = await FirebaseFirestore.instance.collection('users').doc(widget.friend.uid).get();
      final friendProfile = UserProfile.fromMap(friendDoc.data()!, friendDoc.id);
      
      // 2. Arkadaşlık durumunu kontrol et
      final areFriends = await FriendService().isFriend(_currentUserId, widget.friend.uid);

      if (mounted) {
        setState(() {
          isPrivateAccount = friendProfile.isPrivate;
          isFriends = areFriends;
        });
      }

      // 3. Eğer (Açık hesap) VEYA (Gizli ama Arkadaşız) ise verileri çek
      if (!friendProfile.isPrivate || areFriends) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.friend.uid)
            .collection('checklists')
            .get();

        final Map<String, List<ChecklistItem>> loadedData = {};
        double spent = 0;
        int completed = 0;

        for (var doc in snapshot.docs) {
          final List<dynamic> itemsList = doc.data()['items'] ?? [];
          final items = itemsList.map((item) => ChecklistItem.fromMap(item)).toList();
          loadedData[doc.id] = items;
          
          for (var item in items) {
            if (item.checked) {
              spent += item.price;
              completed++;
            }
          }
        }

        if (mounted) {
          setState(() {
            checklistData = loadedData;
            totalSpent = spent;
            totalCompleted = completed;
          });
        }
      }

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Arkadaş verisi çekme hatası: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Calculate Badges
  Widget _buildBadge() {
    int level = totalCompleted ~/ 5;
    if (level < 1) return const SizedBox.shrink();

    String badgeLabel = "";
    Color badgeColor = Colors.grey.shade200;
    String icon = "";

    if (level < 5) {
      badgeLabel = "Bronz Üye";
      badgeColor = Colors.orange.shade100;
      icon = "🥉";
    } else if (level < 10) {
      badgeLabel = "Gümüş Üye";
      badgeColor = Colors.grey.shade300;
      icon = "🥈";
    } else if (level < 20) {
      badgeLabel = "Altın Üye";
      badgeColor = Colors.amber.shade100;
      icon = "🥇";
    } else {
      badgeLabel = "Elmas Üye";
      badgeColor = Colors.cyan.shade100;
      icon = "💎";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text("$icon $badgeLabel", style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // Categories helper
  List<AppCategory> get categories => const [
        AppCategory(
          id: 'salon',
          name: 'Salon',
          icon: '🛋️',
          gradient: [Color(0xff3b82f6), Color(0xff22d3ee)],
        ),
        AppCategory(
          id: 'mutfak',
          name: 'Mutfak',
          icon: '🍳',
          gradient: [Color(0xfff97316), Color(0xfff59e0b)],
        ),
        AppCategory(
          id: 'banyo',
          name: 'Banyo',
          icon: '🚿',
          gradient: [Color(0xff14b8a6), Color(0xff10b981)],
        ),
        AppCategory(
          id: 'yatak-odasi',
          name: 'Yatak Odası',
          icon: '🛏️',
          gradient: [Color(0xff8b5cf6), Color(0xffec4899)],
        ),
        AppCategory(
          id: 'tekstil',
          name: 'Tekstil',
          icon: '🧵',
          gradient: [Color(0xfffb7185), Color(0xffef4444)],
        ),
        AppCategory(
          id: 'mutfak-esyalari',
          name: 'Mutfak Eşyaları',
          icon: '🍽️',
          gradient: [Color(0xff22c55e), Color(0xff84cc16)],
        ),
      ];

  void _showCategoryDetails(AppCategory cat) {
    final items = checklistData[cat.id] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text(cat.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             ),
             Expanded(
               child: items.isEmpty 
               ? const Center(child: Text("Bu kategoride ürün yok"))
               : ListView.builder(
                 itemCount: items.length,
                 padding: const EdgeInsets.all(16),
                 itemBuilder: (context, index) {
                   final item = items[index];
                   return ListTile(
                     leading: Icon(
                       item.checked ? Icons.check_circle : Icons.circle_outlined,
                       color: item.checked ? Colors.green : Colors.grey,
                     ),
                     title: Text(
                       item.name, 
                       style: TextStyle(
                         decoration: item.checked ? TextDecoration.lineThrough : null,
                         color: item.checked ? Colors.grey : Colors.black87
                       )
                     ),
                     trailing: item.price > 0 
                      ? Text("${item.price.toStringAsFixed(0)} ₺")
                      : null,
                   );
                 },
               ),
             )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.friend.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFF3E8FF), Colors.white],
            stops: const [0.0, 0.6],
          )
        ),
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: const Color(0xFFC084FC).withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    )
                                  ]
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
                                ),
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: Colors.white,
                                  backgroundImage: widget.friend.photoUrl != null ? NetworkImage(widget.friend.photoUrl!) : null,
                                  child: widget.friend.photoUrl == null 
                                    ? Text(widget.friend.name[0].toUpperCase(), 
                                        style: const TextStyle(fontSize: 40, color: Color(0xFFC084FC), fontWeight: FontWeight.bold)) 
                                    : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(widget.friend.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xff1f2937))),
                          const SizedBox(height: 8),
                          _buildBadge(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // İçerik Gizleme Mantığı
                    if (isPrivateAccount && !isFriends)
                      _buildPrivateAccountMessage()
                    else ...[
                      // Stats Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: const Color(0xFFF3E8FF).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem("Toplam\nHarcama", "${totalSpent.toStringAsFixed(0)} ₺", Colors.pink),
                              Container(width: 1, height: 40, color: Colors.grey.shade200),
                              _buildStatItem("Tamamlanan\nÜrün", "$totalCompleted", Colors.green),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.centerLeft, 
                          child: Text(
                            "Kategoriler", 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                          )
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Categories Grid/List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final catItems = checklistData[cat.id] ?? [];
                          final count = catItems.length;
                          final checkedCount = catItems.where((i) => i.checked).length;
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () => _showCategoryDetails(cat),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: cat.gradient),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                              ),
                              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text(
                                "$checkedCount / $count tamamlandı",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400)
                              ),
                            ),
                          );
                        },
                      )
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPrivateAccountMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock, size: 80, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            "Bu hesap gizlidir. İçeriği görmek için arkadaş olmalısın.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
