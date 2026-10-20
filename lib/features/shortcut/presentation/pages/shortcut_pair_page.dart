import 'package:bizos/core/di/injection.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/shortcut/data/datasoucre/shortcut_token_local_datasource.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_pair_bloc.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_pair_event.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_pair_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ShortcutPairPage extends StatefulWidget {
  const ShortcutPairPage({super.key});

  @override
  State<ShortcutPairPage> createState() => _ShortcutPairPageState();
}

class _ShortcutPairPageState extends State<ShortcutPairPage> {
  final _deviceNameController = TextEditingController();
  String shortcutUrl =
      'https://www.icloud.com/shortcuts/b009ca040b274fcbb9550b585edf103a';
  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  void _pairShortcut() {
    final deviceName = _deviceNameController.text.trim();

    if (deviceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a device name.')),
      );
      return;
    }

    context.read<ShortcutPairBloc>().add(
      ShortcutPairRequested(deviceName: deviceName),
    );
  }

  Future<void> openShortcutSetup() async {
    final uri = Uri.parse(shortcutUrl);

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Apple Shortcut link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShortcutPairBloc, ShortcutPairState>(
      listener: (context, state) {
        if (state.status == ShortcutPairStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shortcut paired successfully!')),
          );
        } else if (state.status == ShortcutPairStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Pairing failed.')),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Pair Shortcut:-')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.link_rounded, size: 56),
                    const SizedBox(height: 20),
                    const Text(
                      'Connect Apple Shortcuts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter a name for this shortcut device.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<ShortcutPairBloc>().add(
                          ShortcutPairVerificationRequested(
                            code: "99397A4E2AA76634676D8798497448C4",
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Verify Pairing Code'),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          final token =
                              await getIt<ShortcutTokenLocalDatasource>()
                                  .getToken();

                          if (!context.mounted) return;

                          final saved = token != null && token.isNotEmpty;
                          AppLogger.debug("token is  === + $token");
                          AppLogger.debug("saved is  === + $saved");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? 'Shortcut token read successfully!'
                                    : 'No shortcut token found.',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to read shortcut token.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_user),
                      label: const Text('Check Token'),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _deviceNameController,
                      enabled: state.status != ShortcutPairStatus.loading,
                      decoration: const InputDecoration(
                        labelText: 'Device name',
                        hintText: 'e.g. My iPhone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: state.status == ShortcutPairStatus.loading
                          ? null
                          : _pairShortcut,
                      child: state.status == ShortcutPairStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Pair Shortcut'),
                    ),

                    if (state.status == ShortcutPairStatus.success &&
                        state.pairingCode != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Pairing Code',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                state.pairingCode!,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'This code expires in 5 minutes.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
