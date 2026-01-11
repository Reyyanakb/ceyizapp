import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../services/friend_service.dart';
import 'friend_profile_screen.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FriendService _friendService = FriendService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Colors
  final Color _bgStart = const Color(0xFFF3E8FF);
  final Color _bgEnd = const Color(0xFFFCE7F3);
  final Color _accentPurple = const Color(0xFFA855F7); // Purple 500
  final Color _accentPink = const Color(0xFFC084FC); // Purple 400

  Future<void> _handleAccept(String requesterId) async {
    try {
      await _friendService.acceptFriendRequest(_currentUserId, requesterId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Arkadaşlık isteği kabul edildi ✨"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleReject(String requesterId) async {
    try {
      await _friendService.rejectFriendRequest(_currentUserId, requesterId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İstek reddedildi"), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // ignore: deprecated_member_use
          colors: [_bgStart.withOpacity(0.5), Colors.white],
        )
      ),
      child: StreamBuilder<List<UserProfile>>(
        stream: _friendService.getReceivedRequestsStream(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _accentPurple));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Veri bulunamadı"));
          }

          final requests = snapshot.data!;

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(32),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: _accentPurple.withOpacity(0.15), 
                           blurRadius: 30, 
                           offset: const Offset(0, 10),
                           spreadRadius: 5
                         )
                       ]
                     ),
                     child: ShaderMask(
                       shaderCallback: (bounds) => LinearGradient(
                         colors: [_accentPurple, _accentPink],
                       ).createShader(bounds),
                       child: const Icon(
                         Icons.mark_email_read_outlined, 
                         size: 80, 
                         color: Colors.white
                       ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   Text(
                     "Yeni istek yok",
                     style: TextStyle(
                       fontSize: 22, 
                       color: Colors.grey.shade700, 
                       fontWeight: FontWeight.bold
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     "Arkadaşlık isteklerin burada görünecek",
                     style: TextStyle(
                       fontSize: 15, 
                       color: Colors.grey.shade400
                     ),
                   )
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            itemCount: requests.length,
            separatorBuilder: (c, i) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final requester = requests[index];
              return GestureDetector(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: requester)));
                },
                child: _buildRequestCard(requester)
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(UserProfile user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            // ignore: deprecated_member_use
            _bgStart.withOpacity(0.4),
          ]
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: _accentPurple.withOpacity(0.12), 
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 3
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_accentPurple, _accentPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null 
                          ? Text(
                              user.name.substring(0, 1).toUpperCase(), 
                              style: TextStyle(
                                fontSize: 28, 
                                color: _accentPurple,
                                fontWeight: FontWeight.bold
                              )
                            )
                          : null,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accentPink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _accentPink.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1
                            )
                          ]
                        ),
                        child: const Icon(
                          Icons.person_add_rounded, 
                          size: 14, 
                          color: Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1f2937),
                          letterSpacing: 0.3
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded, 
                            size: 15, 
                            color: _accentPurple.withOpacity(0.7)
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accentPurple.withOpacity(0.15),
                              _accentPink.withOpacity(0.15),
                            ]
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.waving_hand_rounded, 
                              size: 14, 
                              color: _accentPurple
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Arkadaş olmak istiyor",
                              style: TextStyle(
                                fontSize: 12,
                                color: _accentPurple,
                                fontWeight: FontWeight.w600
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(user.uid),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    label: const Text("Reddet", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentPurple, _accentPink],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _accentPurple.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6)
                        )
                      ]
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAccept(user.uid),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text("Kabul Et", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}
