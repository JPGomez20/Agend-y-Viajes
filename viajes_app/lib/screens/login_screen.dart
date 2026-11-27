import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoC = TextEditingController();
  final _passC = TextEditingController();
  bool cargando = false;
  String error = '';

  Future<void> ingresar() async {
    setState(() { cargando = true; error = ''; });
    try {
      final res = await supabase.auth.signInWithPassword(email: _correoC.text.trim(), password: _passC.text.trim());
      final userId = res.user!.id;
      final perfil = await supabase.from('perfiles').select().eq('id', userId).single();
      final rol = perfil['rol'] as String;
      final nombre = perfil['nombre'] as String;
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(nombre: nombre, rol: rol)));
    } catch (e) {
      setState(() { error = 'Correo o contraseña incorrectos.'; });
    } finally {
      setState(() { cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(color: Color(0xFF1B7A3D), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28))),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.grass, color: Color(0xFF1B7A3D), size: 30)),
                  SizedBox(height: 16),
                  Text('MAR ANDINO', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  Text('PERUVIAN ANDEAN TROUT SAC', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('Viajes Corporativos', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenido', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Ingresa con tu correo de la empresa', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(controller: _correoC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: _passC, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline))),
                  if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error, style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: cargando ? null : ingresar, child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Ingresar'))),
                  const SizedBox(height: 12),
                  const Center(child: Text('Tu rol lo asigna la empresa, no lo puedes cambiar.', style: TextStyle(fontSize: 12, color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}