import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  Timer? _countdownTimer;

  final Color _primaryColor = const Color(0xFF0052D4);
  final Color _secondaryColor = const Color(0xFF4364F7);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Por favor ingrese su correo';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Por favor ingrese su contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Verificar si ya está bloqueado
    if (authProvider.bloqueado && authProvider.segundosRestantes > 0) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final success = await authProvider.login(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // Si está bloqueado, iniciar countdown
        if (authProvider.bloqueado && authProvider.segundosRestantes > 0) {
          _iniciarCountdown(authProvider);
        } else if (authProvider.intentosRestantes != null) {
      
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              authProvider.limpiarMensajeError();
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _iniciarCountdown(AuthProvider authProvider) {
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final segundos = authProvider.segundosRestantes - 1;

      if (segundos <= 0) {
        timer.cancel();
        authProvider.actualizarSegundosRestantes(0);
      } else {
        authProvider.actualizarSegundosRestantes(segundos);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height * 0.9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'N.S.G Latinoamérica',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  Image.asset(
                    'assets/images/logo.jpg',
                    height: 130,
                    width: 130,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 35),

                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final isLocked = authProvider.bloqueado && 
                                      authProvider.segundosRestantes > 0;

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Campo correo
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                enabled: !isLocked && !_loading,
                                style: GoogleFonts.poppins(fontSize: 16),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email_outlined, color: _primaryColor),
                                  labelText: 'Correo',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                                  filled: true,
                                  fillColor: isLocked ? Colors.grey[200] : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: _primaryColor, width: 1.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Campo contraseña
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                                enabled: !isLocked && !_loading,
                                style: GoogleFonts.poppins(fontSize: 16),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  labelText: 'Contraseña',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                                  filled: true,
                                  fillColor: isLocked ? Colors.grey[200] : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: _primaryColor, width: 1.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Botón de ingresar
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (_loading || isLocked) ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: (_loading || isLocked)
                                          ? null
                                          : LinearGradient(
                                              colors: [_primaryColor, _secondaryColor],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      color: (_loading || isLocked) ? Colors.grey[300] : null,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: _loading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : Text(
                                              isLocked 
                                                ? 'Bloqueado (${authProvider.segundosRestantes}s)' 
                                                : 'Ingresar',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isLocked ? Colors.grey[600] : Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              // Mensaje de error
                              if (authProvider.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isLocked ? Colors.orange[50] : Colors.red[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLocked ? Icons.timer : Icons.error_outline,
                                        color: isLocked ? Colors.orange : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authProvider.error!,
                                          style: GoogleFonts.poppins(
                                            color: isLocked ? Colors.orange[800] : Colors.red[800],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Mostrar intentos restantes
                              if (!isLocked && authProvider.intentosRestantes != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Intentos restantes: ${authProvider.intentosRestantes}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Versión 1.2.0',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2025 N.S.G Latinoamérica',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}