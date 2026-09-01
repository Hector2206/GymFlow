import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart'
    as web;

import '../config/api_config.dart';

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
  late final GoogleSignIn
      googleSignIn;

  StreamSubscription<
          GoogleSignInAccount?>?
      subscription;

  bool procesando = false;

  @override
  void initState() {
    super.initState();

    googleSignIn = GoogleSignIn(
      clientId:
          ApiConfig.googleClientId,
      scopes: const [
        'email',
      ],
    );

    subscription =
        googleSignIn
            .onCurrentUserChanged
            .listen(
      procesarUsuarioGoogle,
    );
  }

  Future<void> procesarUsuarioGoogle(
    GoogleSignInAccount? account,
  ) async {
    if (account == null ||
        procesando) {
      return;
    }

    procesando = true;

    try {
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
      procesando = false;
    }
  }

  @override
  void dispose() {
    subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: web.renderButton(),
      ),
    );
  }
}