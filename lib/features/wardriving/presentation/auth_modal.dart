import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/config/wardrive_config.dart';
import '../data/wardrive_api_repository.dart';
import 'wardrive_controller.dart';

class AuthModal extends ConsumerStatefulWidget {
  const AuthModal({
    required this.profile,
    required this.initialView,
    super.key,
  });

  final DeviceProfile profile;
  final AuthView initialView;

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

enum AuthView { login, register, forgot }

class _AuthModalState extends ConsumerState<AuthModal> {
  late AuthView _view;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  var _isSubmitting = false;
  var _error = '';
  var _success = '';

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  WardriveController get _controller =>
      ref.read(wardriveControllerProvider(widget.profile).notifier);

  WardriveApiRepository get _api => ref.read(wardriveApiProvider);

  Future<void> _submit() async {
    setState(() {
      _error = '';
      _success = '';
      _isSubmitting = true;
    });

    try {
      if (_view == AuthView.login) {
        final data = await _api.login(
          _usernameController.text,
          _passwordController.text,
        );
        await _controller.saveAuth(
          access: data.access,
          refresh: data.refresh,
          username: data.username,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
        if (_controller.consumePendingUploadAll()) {
          await _controller.requestUploadAll();
        }
      } else if (_view == AuthView.register) {
        final data = await _api.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirm: _passwordConfirmController.text,
        );
        await _controller.saveAuth(
          access: data.tokens.access,
          refresh: data.tokens.refresh,
          username: data.user.username,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
        if (_controller.consumePendingUploadAll()) {
          await _controller.requestUploadAll();
        }
      } else {
        await _api.requestPasswordReset(_emailController.text);
        setState(() {
          _success =
              'Si el correo está registrado, recibirás instrucciones para restablecerla.';
        });
      }
    } on ApiConfigError catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(switch (_view) {
        AuthView.login => 'Log in',
        AuthView.register => 'Register',
        AuthView.forgot => 'Reset password',
      }),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_view != AuthView.forgot) ...[
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
            ],
            if (_view != AuthView.login) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
            ],
            if (_view != AuthView.forgot) ...[
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
            ],
            if (_view == AuthView.register) ...[
              TextField(
                controller: _passwordConfirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.redAccent)),
            if (_success.isNotEmpty)
              Text(_success, style: const TextStyle(color: Colors.greenAccent)),
            const SizedBox(height: 8),
            _AuthViewLinks(
              view: _view,
              onSwitch: (view) => setState(() {
                _view = view;
                _error = '';
                _success = '';
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

Future<bool?> showAuthModal(
  BuildContext context,
  WidgetRef ref,
  DeviceProfile profile, {
  AuthView view = AuthView.login,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AuthModal(profile: profile, initialView: view),
  );
}

class _AuthViewLinks extends StatelessWidget {
  const _AuthViewLinks({required this.view, required this.onSwitch});

  final AuthView view;
  final ValueChanged<AuthView> onSwitch;

  @override
  Widget build(BuildContext context) {
    return switch (view) {
      AuthView.login => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => onSwitch(AuthView.register),
            child: const Text('Create account'),
          ),
          TextButton(
            onPressed: () => onSwitch(AuthView.forgot),
            child: const Text('Forgot password?'),
          ),
        ],
      ),
      AuthView.register => TextButton(
        onPressed: () => onSwitch(AuthView.login),
        child: const Text('Already have an account? Log in'),
      ),
      AuthView.forgot => TextButton(
        onPressed: () => onSwitch(AuthView.login),
        child: const Text('Back to log in'),
      ),
    };
  }
}
