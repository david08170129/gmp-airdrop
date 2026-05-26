import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/gmp_colors.dart';
import '../../widgets/gmp_logo.dart';
import 'ios_native_picker_service.dart';
import 'ios_share_inbox_service.dart';
import 'ios_wireless_upload_service.dart';

class IosCompanionShell extends StatefulWidget {
  const IosCompanionShell({super.key});

  @override
  State<IosCompanionShell> createState() => _IosCompanionShellState();
}

class _IosCompanionShellState extends State<IosCompanionShell> {
  int _index = 0;
  bool _autoOpenedNearbyDevice = false;

  Future<void> _startNearbyListener() async {
    _listenerSocket ??= await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      45454,
      reuseAddress: true,
      reusePort: true,
    );

    _listenerSocket!.listen((event) {
      if (event != RawSocketEvent.read) return;

      final datagram = _listenerSocket!.receive();
      if (datagram == null) return;

      try {
        final payload = jsonDecode(
          utf8.decode(datagram.data),
        );

        final uri = Uri.parse(payload['url']);

        final device = NearbyDevice(
          name: payload['name'],
          ip: uri.host,
          port: uri.port,
          url: payload['url'],
        );

        final exists = _nearbyDevices.any(
          (d) => d.ip == device.ip,
        );

        if (!exists) {
          setState(() {
            _nearbyDevices.add(device);
          });
        }

        if (!_autoOpenedNearbyDevice) {
          _autoOpenedNearbyDevice = true;

          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _EmbeddedUploadPage(
                  url: device.url,
                  title: device.name,
                ),
              ),
            );
          });
        }
      } catch (_) {}
    });
  }

  RawDatagramSocket? _listenerSocket;

  final List<NearbyDevice> _nearbyDevices = [];

  final _history = const [
    IosTransferHistoryItem(
      title: 'Safari upload session',
      subtitle: 'Ready for GMP Airdrop QR links',
      status: 'Prepared',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startNearbyListener();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardingPage(
        onScanPressed: () => setState(() => _index = 1),
        devices: _nearbyDevices,
      ),
      const _QrScannerPage(),
      const _UploadWebPage(),
      const _SharedFilesPage(),
      _TransferHistoryPage(items: _history),
    ];

    return Scaffold(
      backgroundColor: GmpColors.background,
      appBar: AppBar(
        toolbarHeight: 76,
        title: const GmpLogo(height: 48),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: () => setState(() => _index = 1),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan'),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_rounded),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.ios_share_rounded),
            label: 'Share',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _IosPage extends StatelessWidget {
  const _IosPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: GmpColors.text,
                fontWeight: FontWeight.w800,
                height: 1.04,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: GmpColors.muted,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.onScanPressed,
    required this.devices,
  });

  final VoidCallback onScanPressed;
  final List<NearbyDevice> devices;

  @override
  Widget build(BuildContext context) {
    return _IosPage(
      title: 'Send from iPhone with less friction.',
      subtitle:
          'Scan a GMP Airdrop QR code, open the local upload page, and share files without cloud accounts.',
      children: [
        _HeroPanel(onScanPressed: onScanPressed),
        const SizedBox(height: 16),
        const _StepCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Scan GMP Airdrop QR codes',
          body: 'Use the companion scanner for Windows or Android receivers.',
        ),
        const _StepCard(
          icon: Icons.public_rounded,
          title: 'Open the upload page',
          body:
              'Launch Safari handoff or embedded upload view for local Wi-Fi transfers.',
        ),
        const _StepCard(
          icon: Icons.ios_share_rounded,
          title: 'Share into GMP Airdrop',
          body:
              'Prepare Share Sheet intake for photos, videos, PDFs, and files.',
        ),
        _NearbyDevicesCard(devices: devices),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onScanPressed});

  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GmpColors.text,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_tethering_rounded,
              color: Colors.white, size: 34),
          const SizedBox(height: 34),
          Text(
            'Offline. Fast. Organized.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Local network transfer first. No account, no cloud relay, no iPhone receive server.',
            style: TextStyle(color: Color(0xFFC9D4E5), height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onScanPressed,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan QR code'),
          ),
        ],
      ),
    );
  }
}

class _QrScannerPage extends StatelessWidget {
  const _QrScannerPage();

  @override
  Widget build(BuildContext context) {
    return _IosPage(
      title: 'Scan a receiver QR code.',
      subtitle:
          'MVP hook for camera-based GMP Airdrop QR scanning. It will accept local HTTP upload URLs from Windows and Android receivers.',
      children: const [
        _ScannerPlaceholder(),
        SizedBox(height: 16),
        _ImplementationNote(
          title: 'Implementation contract',
          body:
              'Add a camera QR plugin, validate local-network URLs, then open the embedded upload view or Safari handoff.',
        ),
      ],
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;

                for (final barcode in barcodes) {
                  final raw = barcode.rawValue;

                  if (raw != null) {
                    final uri = Uri.parse(raw);

                    launchUrl(uri);
                  }
                }
              },
            ),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadWebPage extends StatelessWidget {
  const _UploadWebPage();

  @override
  Widget build(BuildContext context) {
    return _IosPage(
      title: 'Upload page bridge.',
      subtitle:
          'Structure for opening the existing GMP Airdrop browser upload page in WKWebView or Safari.',
      children: const [
        _UploadUrlCard(),
        SizedBox(height: 16),
        _ImplementationNote(
          title: 'No new transfer protocol',
          body:
              'The companion app reuses the current QR upload URL and mobile browser upload flow.',
        ),
      ],
    );
  }
}

class _UploadUrlCard extends StatelessWidget {
  const _UploadUrlCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: GmpColors.blue),
          const SizedBox(height: 14),
          Text(
            'Waiting for QR upload URL',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Example: http://192.168.1.24:8080/upload',
            style: TextStyle(color: GmpColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: null,
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open in Safari'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharedFilesPage extends StatefulWidget {
  const _SharedFilesPage();

  @override
  State<_SharedFilesPage> createState() => _SharedFilesPageState();
}

class _SharedFilesPageState extends State<_SharedFilesPage>
    with WidgetsBindingObserver {
  final _service = IosShareInboxService();
  List<IosSharedBatch> _batches = const [];
  bool _loading = true;
  bool _clearing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadInbox());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadInbox(silent: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedItems = _batches.expand((batch) => batch.items).toList();

    return _IosPage(
      title: 'Share Sheet intake.',
      subtitle:
          'Files sent to GMP Airdrop from Photos, Files, Safari, and other iOS apps appear here.',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: _loading || _clearing ? null : _loadInbox,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
            FilledButton.tonalIcon(
              onPressed:
                  sharedItems.isEmpty || _loading || _clearing ? null : _clear,
              icon: _clearing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_status != null)
          _GlassCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: GmpColors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status!,
                    style: const TextStyle(color: GmpColors.muted),
                  ),
                ),
              ],
            ),
          ),
        if (_status != null) const SizedBox(height: 16),
        if (_loading && _batches.isEmpty)
          const _GlassCard(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (sharedItems.isEmpty)
          const _EmptyStateCard(
            icon: Icons.ios_share_rounded,
            title: 'No shared files yet',
            body:
                'Use the iOS Share Sheet in Photos, Files, Safari, or another app and choose GMP Airdrop.',
          )
        else
          for (final batch in _batches) ...[
            _SharedBatchCard(batch: batch),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Future<void> _loadInbox({bool silent = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      if (!silent) _status = null;
    });

    try {
      final batches = await _service.getSharedInbox();
      if (!mounted) return;
      setState(() {
        _batches = batches;
        _status = batches.isEmpty
            ? null
            : '${batches.expand((batch) => batch.items).length} shared item(s) ready.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Could not load shared files: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _clear() async {
    setState(() {
      _clearing = true;
      _status = 'Clearing shared files...';
    });

    try {
      final ids = _batches.map((batch) => batch.id).toList();
      final cleared = await _service.clearSharedInbox(ids);
      if (!mounted) return;
      setState(() {
        if (cleared) {
          _batches = const [];
          _status = 'Shared files cleared.';
        } else {
          _status = 'Some shared files could not be cleared.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Could not clear shared files: $error');
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }
}

class _SharedBatchCard extends StatelessWidget {
  const _SharedBatchCard({required this.batch});

  final IosSharedBatch batch;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ios_share_rounded, color: GmpColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${batch.items.length} shared item(s)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                _formatDate(batch.receivedAt),
                style: const TextStyle(color: GmpColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in batch.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _iconForType(item.type),
                color: item.exists || item.path.isEmpty
                    ? GmpColors.blue
                    : Colors.orange,
              ),
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _itemSubtitle(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: item.path.isNotEmpty && !item.exists
                  ? const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange)
                  : null,
            ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) {
    return switch (type) {
      'image' => Icons.image_rounded,
      'video' => Icons.movie_rounded,
      'pdf' => Icons.picture_as_pdf_rounded,
      'text' => Icons.notes_rounded,
      'url' => Icons.link_rounded,
      'error' => Icons.error_outline_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  static String _itemSubtitle(IosSharedItem item) {
    if (item.message != null && item.message!.isNotEmpty) {
      return item.message!;
    }

    final details = <String>[
      item.type,
      if (item.sizeBytes > 0) _formatBytes(item.sizeBytes),
      if (item.uti.isNotEmpty) item.uti,
      if (item.path.isNotEmpty && !item.exists) 'file missing',
    ];
    return details.join(' - ');
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final decimals = unitIndex == 0 || size >= 10 ? 0 : 1;
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }
}

class _TransferHistoryPage extends StatelessWidget {
  const _TransferHistoryPage({required this.items});

  final List<IosTransferHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return _IosPage(
      title: 'Transfer history.',
      subtitle:
          'A lightweight local record of iPhone upload sessions and shared-file handoffs.',
      children: [
        for (final item in items)
          _GlassCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, color: GmpColors.blue),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: Text(
                item.status,
                style: const TextStyle(
                  color: GmpColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: GmpColors.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      color: GmpColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImplementationNote extends StatelessWidget {
  const _ImplementationNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: GmpColors.blue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(color: GmpColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Icon(icon, size: 44, color: GmpColors.blue),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: GmpColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GmpColors.line.withValues(alpha: 0.76)),
        boxShadow: [
          BoxShadow(
            color: GmpColors.blue.withValues(alpha: 0.04),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class IosTransferHistoryItem {
  const IosTransferHistoryItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;
}

class _NearbyDevicesCard extends StatelessWidget {
  const _NearbyDevicesCard({
    required this.devices,
  });

  final List<NearbyDevice> devices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: GmpColors.blue.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_tethering_rounded,
                color: GmpColors.blue,
              ),
              const SizedBox(width: 10),
              const Text(
                'Nearby devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (devices.isEmpty)
            const Text(
              'Searching local Wi-Fi for GMP AirDrop receivers...',
              style: TextStyle(color: GmpColors.muted),
            )
          else
            ...devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _EmbeddedUploadPage(
                          url: device.url,
                          title: device.name,
                        ),
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: GmpColors.blue.withValues(alpha: 0.06),
                  leading: Icon(
                    Icons.desktop_windows_rounded,
                    color: GmpColors.blue,
                  ),
                  title: Text(device.name),
                  subtitle: Text(device.ip),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NearbyDevice {
  const NearbyDevice({
    required this.name,
    required this.ip,
    required this.port,
    required this.url,
  });

  final String name;
  final String ip;
  final int port;
  final String url;
}

class _EmbeddedUploadPage extends StatefulWidget {
  const _EmbeddedUploadPage({
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<_EmbeddedUploadPage> createState() => _EmbeddedUploadPageState();
}

class _EmbeddedUploadPageState extends State<_EmbeddedUploadPage> {
  final _picker = IosNativePickerService();
  final _uploader = IosWirelessUploadService();
  final List<IosPickedFile> _selectedFiles = [];

  bool _picking = false;
  bool _uploading = false;
  double _progress = 0;
  String? _status;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title),
              const Text(
                'Local Wi-Fi transfer',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(widget.url)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            const Text(
              'Local Wi-Fi transfer',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
        children: [
          Text(
            'Send to GMP Airdrop',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: GmpColors.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose existing photos, videos, or files. Camera capture is not used.',
            style: TextStyle(color: GmpColors.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _NativePickButton(
                icon: Icons.photo_library_rounded,
                label: 'Photo Library',
                enabled: !_picking && !_uploading,
                onPressed: () => _pick(IosPickerKind.photos),
              ),
              _NativePickButton(
                icon: Icons.video_library_rounded,
                label: 'Videos',
                enabled: !_picking && !_uploading,
                onPressed: () => _pick(IosPickerKind.videos),
              ),
              _NativePickButton(
                icon: Icons.folder_rounded,
                label: 'Choose Files',
                enabled: !_picking && !_uploading,
                onPressed: () => _pick(IosPickerKind.files),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file_rounded,
                        color: GmpColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_selectedFiles.length} file(s) selected',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    if (_selectedFiles.isNotEmpty && !_uploading)
                      IconButton(
                        tooltip: 'Clear selection',
                        onPressed: () => setState(_selectedFiles.clear),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selectedFiles.isEmpty)
                  const Text(
                    'No files selected yet.',
                    style: TextStyle(color: GmpColors.muted),
                  )
                else
                  ..._selectedFiles.map(
                    (file) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.insert_drive_file_rounded),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatBytes(file.sizeBytes)),
                    ),
                  ),
                if (_uploading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _progress.clamp(0, 1)),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _status!,
                    style: const TextStyle(
                      color: GmpColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _selectedFiles.isEmpty || _uploading
                      ? null
                      : _uploadSelectedFiles,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_uploading ? 'Sending...' : 'Send files'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(IosPickerKind kind) async {
    setState(() {
      _picking = true;
      _status = null;
    });

    try {
      final files = await _picker.pick(kind);
      if (!mounted) return;
      setState(() {
        _selectedFiles.addAll(files);
        if (files.isEmpty) {
          _status = 'No files selected.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Could not select files: $error');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _uploadSelectedFiles() async {
    setState(() {
      _uploading = true;
      _progress = 0;
      _status = 'Starting upload...';
    });

    try {
      final count = await _uploader.upload(
        receiverUrl: Uri.parse(widget.url),
        files: List<IosPickedFile>.of(_selectedFiles),
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progress = progress.value;
            _status = 'Uploading ${(_progress * 100).toStringAsFixed(0)}%';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _selectedFiles.clear();
        _progress = 1;
        _status = '$count file(s) uploaded to ${widget.title}.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Upload failed: $error');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final decimals = unitIndex == 0 || size >= 10 ? 0 : 1;
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }
}

class _NativePickButton extends StatelessWidget {
  const _NativePickButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
