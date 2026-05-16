import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/gmp_colors.dart';
import '../../widgets/gmp_logo.dart';

class IosCompanionShell extends StatefulWidget {
  const IosCompanionShell({super.key});

  @override
  State<IosCompanionShell> createState() => _IosCompanionShellState();
}

class _IosCompanionShellState extends State<IosCompanionShell> {
  int _index = 0;

Future<void> _startNearbyListener() async {
  _listenerSocket ??=
      await RawDatagramSocket.bind(
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
          body: 'Launch Safari handoff or embedded upload view for local Wi-Fi transfers.',
        ),
        

const _StepCard(
  icon: Icons.ios_share_rounded,
  title: 'Share into GMP Airdrop',
  body: 'Prepare Share Sheet intake for photos, videos, PDFs, and files.',
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

class _SharedFilesPage extends StatelessWidget {
  const _SharedFilesPage();

  @override
  Widget build(BuildContext context) {
    return _IosPage(
      title: 'Share Sheet intake.',
      subtitle:
          'Initial surface for files sent to GMP Airdrop from Photos, Files, Safari, and other iOS apps.',
      children: const [
        _EmptyStateCard(
          icon: Icons.ios_share_rounded,
          title: 'No shared files yet',
          body:
              'Native Share Extension wiring will stage selected files here before opening the upload flow.',
        ),
      ],
    );
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

class _EmbeddedUploadPage extends StatelessWidget {
  const _EmbeddedUploadPage({
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
     
     
      
   body: WebViewWidget(
  controller: WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(url)),
),
   
   
    );
  }
}