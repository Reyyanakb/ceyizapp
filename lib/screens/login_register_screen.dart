import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class LoginRegisterScreen extends StatefulWidget {
  final void Function(AppUser user) onLogin;
  const LoginRegisterScreen({super.key, required this.onLogin});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool isLogin = true;
  bool isLoading = false;
  String name = '';
  String email = '';
  String password = '';
  String error = '';
  
  final List<String> avatars = ['👩‍🦰', '👩🏾‍🦱', '👱‍♀️', '🧕', '🧑‍🦱', '🧔'];
  int selectedAvatar = 0;

  // Soft Palette
  final Color _purpleLight = const Color(0xFFF3E8FF);
  final Color _pinkLight = const Color(0xFFFCE7F3);
  final Color _primaryColor = const Color(0xFFC084FC); // Soft Purple
  final Color _secondaryColor = const Color(0xFFF472B6); // Soft Pink

  void submit() async {
    setState(() {
      error = '';
      if (email.trim().length < 3 || !email.contains('@')) {
        error = 'Geçerli bir email giriniz';
        return;
      }
      if (password.length < 6) {
        error = 'Şifre en az 6 karakter olmalı';
        return;
      }
      if (!isLogin && name.trim().length < 2) {
        error = 'İsim en az 2 karakter olmalı';
        return;
      }
      isLoading = true;
    });

    try {
      UserCredential userCredential;

      if (isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } else {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        
        await userCredential.user?.updateDisplayName(name.trim());
        String avatarUrl = avatars[selectedAvatar];
        await userCredential.user?.updatePhotoURL(avatarUrl);

        // Firestore User Document Creation
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'photoUrl': avatarUrl,
          'friends': [],
          'sentRequests': [],
          'receivedRequests': [],
          'createdAt': FieldValue.serverTimestamp(),
          'checklists': {} // Optional initialization
        });
      }

      final user = AppUser(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? (isLogin ? 'Kullanıcı' : name.trim()),
        email: email.trim(),
        avatar: userCredential.user!.photoURL ?? avatars[selectedAvatar],
      );
      
      widget.onLogin(user);

    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') error = 'Kullanıcı bulunamadı.';
        else if (e.code == 'wrong-password') error = 'Hatalı şifre.';
        else if (e.code == 'email-already-in-use') error = 'E-posta zaten kayıtlı.';
        else if (e.code == 'invalid-email') error = 'Geçersiz e-posta.';
        else error = 'Hata: ${e.message}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Soft dreamy gradient
            colors: [_purpleLight, Colors.white, _pinkLight],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 30, spreadRadius: 10),
                    ],
                    gradient: LinearGradient(
                      colors: [_primaryColor.withOpacity(0.8), _secondaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft, 
                      end: Alignment.bottomRight
                    )
                  ),
                  // İkonu silip yerine resim ekliyoruz:
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'Çeyiz Listem', 
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.grey.shade800,
                    letterSpacing: -0.5
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Hoşgeldiniz, tekrar görmek harika!' : 'Yeni bir başlangıca hazır mısın?',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), // Glass-ish
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.05),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildToggleBtn('Giriş', isLogin)),
                            Expanded(child: _buildToggleBtn('Kayıt Ol', !isLogin)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (!isLogin) ...[
                        _buildTextField('Ad Soyad', Icons.badge_rounded, (v) => name = v),
                        const SizedBox(height: 16),
                        _buildAvatarSelector(),
                        const SizedBox(height: 24),
                      ],

                      _buildTextField('E-posta', Icons.email_rounded, (v) => email = v, isEmail: true),
                      const SizedBox(height: 16),
                      _buildTextField('Şifre', Icons.lock_rounded, (v) => password = v, isPass: true),

                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(error, style: TextStyle(color: Colors.red.shade700, fontSize: 13), textAlign: TextAlign.center),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _secondaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            shadowColor: _secondaryColor.withOpacity(0.5),
                          ).copyWith(
                            elevation: MaterialStateProperty.all(10), 
                          ),
                          child: isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isLogin ? 'Giriş Yap' : 'Hesap Oluştur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool active) {
    return GestureDetector(
      onTap: () {
        if (!active) setState(() => isLogin = !isLogin);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: active ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String) onChanged, {bool isPass = false, bool isEmail = false}) {
    return TextFormField(
      obscureText: isPass,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.grey.shade50.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: avatars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final isSelected = selectedAvatar == i;
          return GestureDetector(
            onTap: () => setState(() => selectedAvatar = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.grey.shade200, 
                  width: 2
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(avatars[i], style: const TextStyle(fontSize: 24))),
            ),
          );
        },
      ),
    );
  }
}