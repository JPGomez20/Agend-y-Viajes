import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFF1B7A3D),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.directions_car, color: Color(0xFF1B7A3D), size: 30)),
                  SizedBox(height: 16),
                  Text('Viajes Empresa', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('Centros de cultivo • Taxi corporativo', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenido', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Ingresa para solicitar o gestionar un viaje', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Tu nombre', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 14),
                  TextField(controller: _correoController, decoration: const InputDecoration(labelText: 'Correo empresa', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_nombreController.text.isEmpty) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(nombre: _nombreController.text)));
                    },
                    child: const Text('Ingresar'),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: Text('Versión interna • Solo personal autorizado', style: TextStyle(fontSize: 12, color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

