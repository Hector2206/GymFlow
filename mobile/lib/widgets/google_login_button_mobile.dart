import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleLoginButton
    extends StatefulWidget {
  final Future<void> Function(
    String idToken,
  ) onToken;

  final void Function(
    String mensaje,
  ) onError;

  const GoogleLoginButton({
    super.key,
    required this.onToken,
    required this.onError,
  });

  @override
  State<GoogleLoginButton> createState() =>
      _GoogleLoginButtonState();
}

class _GoogleLoginButtonState
    extends State<GoogleLoginButton> {
  bool procesando = false;

  Future<void> iniciarGoogle() async {
    if (procesando) {
      return;
    }

    setState(() {
      procesando = true;
    });

    try {
        final googleSignIn =
          GoogleSignIn(
        scopes: const [
          'email',
        ],
        serverClientId:
            '403800585371-gvse8f49bhq6gqh1tmvmk1t8sebg6rvs.apps.googleusercontent.com',
      );

      final account =
          await googleSignIn
              .signIn();

      if (account == null) {
        return;
      }

      final authentication =
          await account
              .authentication;

      final idToken =
          authentication.idToken;

      if (idToken == null ||
          idToken.isEmpty) {
        widget.onError(
          'Google no devolvió un token válido.',
        );

        return;
      }

      await widget.onToken(
        idToken,
      );
    } catch (_) {
      widget.onError(
        'No se pudo completar el inicio de sesión con Google.',
      );
    } finally {
      if (mounted) {
        setState(() {
          procesando = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed:
            procesando
                ? null
                : iniciarGoogle,
        icon: procesando
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      Color(
                    0xFFD4AF37,
                  ),
                ),
              )
            : const Icon(
                Icons.login,
              ),
        label: Text(
          procesando
              ? 'Iniciando sesión...'
              : 'Continuar con Google',
        ),
      ),
    );
  }
}