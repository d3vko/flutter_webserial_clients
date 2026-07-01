import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/config/wardrive_config.dart';
import '../../wardriving/data/wardrive_api_repository.dart';
import '../../wardriving/presentation/wardrive_controller.dart';
import 'marauder_controller.dart';

enum MarauderAuthView { login, register, forgot }

class MarauderAuthModal extends ConsumerStatefulWidget {
  const MarauderAuthModal({
    required this.profile,
    required this.initialView,
    super.key,
  });

  final DeviceProfile profile;
  final MarauderAuthView initialView;

  @override
  ConsumerState<MarauderAuthModal> createState() => _MarauderAuthModalState();
}

class _MarauderAuthModalState extends ConsumerState<MarauderAuthModal> {
  late MarauderAuthView _view;
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

  MarauderController get _controller =>
      ref.read(marauderControllerProvider(widget.profile).notifier);

  WardriveApiRepository get _api => ref.read(wardriveApiProvider);

  Future<void> _submit() async {
    setState(() {
      _error = '';
      _success = '';
      _isSubmitting = true;
    });

    try {
      switch (_view) {
        case MarauderAuthView.login:
          final response = await _api.login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
          await _controller.saveAuth(
            access: response.access,
            refresh: response.refresh,
            username: response.username,
          );
          if (mounted) Navigator.of(context).pop(true);
        case MarauderAuthView.register:
          final response = await _api.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirm: _passwordConfirmController.text,
          );
          await _controller.saveAuth(
            access: response.tokens.access,
            refresh: response.tokens.refresh,
            username: response.user.username,
          );
          if (mounted) Navigator.of(context).pop(true);
        case MarauderAuthView.forgot:
          final response = await _api.requestPasswordReset(
            _emailController.text.trim(),
          );
          setState(() => _success = response.detail);
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
        MarauderAuthView.login => 'Log in',
        MarauderAuthView.register => 'Register',
        MarauderAuthView.forgot => 'Reset password',
      }),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_view != MarauderAuthView.forgot)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            if (_view == MarauderAuthView.register ||
                _view == MarauderAuthView.forgot) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
            if (_view != MarauderAuthView.forgot) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
            if (_view == MarauderAuthView.register) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordConfirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
            ],
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.redAccent)),
            ],
            if (_success.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_success, style: const TextStyle(color: Colors.greenAccent)),
            ],
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

Future<bool?> showMarauderAuthModal(
  BuildContext context,
  WidgetRef ref,
  DeviceProfile profile, {
  MarauderAuthView view = MarauderAuthView.login,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) =>
        MarauderAuthModal(profile: profile, initialView: view),
  );
}

class _AuthViewLinks extends StatelessWidget {
  const _AuthViewLinks({required this.view, required this.onSwitch});

  final MarauderAuthView view;
  final ValueChanged<MarauderAuthView> onSwitch;

  @override
  Widget build(BuildContext context) {
    return switch (view) {
      MarauderAuthView.login => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => onSwitch(MarauderAuthView.register),
            child: const Text('Create account'),
          ),
          TextButton(
            onPressed: () => onSwitch(MarauderAuthView.forgot),
            child: const Text('Forgot password?'),
          ),
        ],
      ),
      MarauderAuthView.register => TextButton(
        onPressed: () => onSwitch(MarauderAuthView.login),
        child: const Text('Already have an account? Log in'),
      ),
      MarauderAuthView.forgot => TextButton(
        onPressed: () => onSwitch(MarauderAuthView.login),
        child: const Text('Back to log in'),
      ),
    };
  }
}
