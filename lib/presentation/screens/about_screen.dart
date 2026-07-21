import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/feedback_service.dart';
import '../providers/riverpod/auth_notifier.dart';

const _privacyUrl =
    'https://hoquem.github.io/hoque-family-chores/PRIVACY_POLICY.html';
const _termsUrl =
    'https://hoquem.github.io/hoque-family-chores/TERMS_AND_CONDITIONS.html';

/// About + feedback. Shows the app version, links to the legal docs, and lets
/// anyone send feedback or request a feature.
class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  final _message = TextEditingController();
  FeedbackType _type = FeedbackType.general;
  bool _sending = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _message.text.trim();
    if (message.isEmpty) return;
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(feedbackServiceProvider).submit(
            message: message,
            type: _type,
            userId: user.id.value,
            familyId: user.familyId.value.isEmpty ? null : user.familyId.value,
            appVersion: _version,
          );
      if (!mounted) return;
      _message.clear();
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your feedback was sent. 💛')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't send that — please try again. ($e)")),
      );
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.home_rounded, size: 56, color: Color(0xFFE08A1E)),
                const SizedBox(height: 8),
                Text('Chores Star',
                    style: Theme.of(context).textTheme.titleLarge),
                if (_version.isNotEmpty)
                  Text('Version $_version',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Send feedback',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tell us what you like, what is broken, or what you wish it did.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SegmentedButton<FeedbackType>(
            key: const Key('feedback_type'),
            segments: [
              for (final t in FeedbackType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('feedback_message'),
            controller: _message,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Your message…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('feedback_send'),
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_sending ? 'Sending…' : 'Send feedback'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(_privacyUrl),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(_termsUrl),
          ),
        ],
      ),
    );
  }
}
