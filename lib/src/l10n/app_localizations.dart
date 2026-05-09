import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _values = {
    'en': {
      'appName': 'GMP Airdrop',
      'tagline': 'Transfer without limits',
      'home': 'Home',
      'usb': 'USB',
      'wirelessReceive': 'Wireless Receive',
      'sendToPhone': 'Send to Phone',
      'export': 'Export',
      'import': 'Import',
      'history': 'History',
      'search': 'Search',
      'settings': 'Settings',
      'mobile': 'Mobile',
      'windows': 'Windows',
      'homeTitle': 'Transfer files simply.\nOffline. Fast. Organized.',
      'homeSubtitle': 'iPhone • Android • USB-C • Windows',
      'readyStatus': 'Ready for offline transfer',
      'selectedFiles': 'Selected files',
      'detectedDrive': 'Detected drive',
      'lastTransfer': 'Last transfer',
      'recentTransferSummary': 'Recent transfer summary',
      'photosTransferred': 'Photos transferred',
      'videosTransferred': 'Videos transferred',
      'documentsTransferred': 'Documents transferred',
      'phoneUsbPc': 'Phone → USB → PC',
      'deviceConnection': 'Device connection',
      'usbDriveConnected': 'USB Drive Connected',
      'readyForTransfer': 'Ready for transfer',
      'quickActions': 'Quick actions',
      'selectPhotos': 'Select photos',
      'selectVideos': 'Select videos',
      'selectFiles': 'Select files',
      'exportToUsb': 'Export to USB-C drive',
      'usbDetection': 'USB drive detection',
      'usbDestination': 'USB-C destination',
      'chooseDrive': 'Choose drive',
      'windowsImport': 'Windows import',
      'detectDrive': 'Detect USB drive',
      'scanUsb': 'Scan USB drives',
      'driveReady': 'GMP_Airdrop folder found',
      'noDrive': 'No GMP drive detected',
      'createStructure': 'Create GMP_Airdrop structure',
      'folderPlan': 'Folder plan',
      'exportWorkflow': 'Export workflow',
      'selectedItems': 'Selected items',
      'categorization': 'File categorization',
      'destination': 'Destination',
      'startExport': 'Start export',
      'exportComplete': 'Export complete',
      'importWorkflow': 'Import workflow',
      'fileCounts': 'File counts',
      'importFiles': 'Import files',
      'importComplete': 'Import complete',
      'manualSearch': 'Manual search',
      'searchHint': 'Search by filename, type, or date',
      'language': 'Language',
      'systemLanguage': 'System language',
      'english': 'English',
      'chinese': 'Chinese',
      'platforms': 'Platforms',
      'storage': 'Storage',
      'privacy': 'Privacy',
      'offlineOnly': 'Offline transfer only',
      'photos': 'Photos',
      'videos': 'Videos',
      'documents': 'Documents',
      'code': 'Code',
      'others': 'Others',
      'waiting': 'Waiting',
      'ready': 'Ready',
      'completed': 'Completed',
      'emptyHistory': 'No transfer history yet',
      'noResults': 'No matching files',
    },
    'zh': {
      'appName': 'GMP Airdrop',
      'tagline': '无限制传输',
      'home': '首页',
      'usb': 'USB',
      'wirelessReceive': '无线接收',
      'sendToPhone': '发送到手机',
      'export': '导出',
      'import': '导入',
      'history': '历史',
      'search': '搜索',
      'settings': '设置',
      'mobile': '手机',
      'windows': 'Windows',
      'homeTitle': '简单传输文件。\n离线、快速、有序。',
      'homeSubtitle': 'iPhone • Android • USB-C • Windows',
      'readyStatus': '已准备好离线传输',
      'selectedFiles': '已选择文件',
      'detectedDrive': '已检测设备',
      'lastTransfer': '最近传输',
      'recentTransferSummary': '最近传输摘要',
      'photosTransferred': '照片已传输',
      'videosTransferred': '视频已传输',
      'documentsTransferred': '文档已传输',
      'phoneUsbPc': '手机 → USB → PC',
      'deviceConnection': '设备连接',
      'usbDriveConnected': 'USB 设备已连接',
      'readyForTransfer': '已准备传输',
      'quickActions': '快捷操作',
      'selectPhotos': '选择照片',
      'selectVideos': '选择视频',
      'selectFiles': '选择文件',
      'exportToUsb': '导出到 USB-C U 盘',
      'usbDetection': 'USB 设备检测',
      'usbDestination': 'USB-C 目标位置',
      'chooseDrive': '选择 U 盘',
      'windowsImport': 'Windows 导入',
      'detectDrive': '检测 U 盘',
      'scanUsb': '扫描 USB 设备',
      'driveReady': '已找到 GMP_Airdrop 文件夹',
      'noDrive': '未检测到 GMP 设备',
      'createStructure': '创建 GMP_Airdrop 目录',
      'folderPlan': '文件夹规划',
      'exportWorkflow': '导出流程',
      'selectedItems': '已选择项目',
      'categorization': '文件分类',
      'destination': '目标位置',
      'startExport': '开始导出',
      'exportComplete': '导出完成',
      'importWorkflow': '导入流程',
      'fileCounts': '文件统计',
      'importFiles': '导入文件',
      'importComplete': '导入完成',
      'manualSearch': '手动搜索',
      'searchHint': '按文件名、类型或日期搜索',
      'language': '语言',
      'systemLanguage': '跟随系统',
      'english': '英文',
      'chinese': '中文',
      'platforms': '平台',
      'storage': '存储',
      'privacy': '隐私',
      'offlineOnly': '仅离线传输',
      'photos': '照片',
      'videos': '视频',
      'documents': '文档',
      'code': '代码',
      'others': '其他',
      'waiting': '等待中',
      'ready': '已就绪',
      'completed': '已完成',
      'emptyHistory': '暂无传输历史',
      'noResults': '没有匹配文件',
    },
  };

  String text(String key) {
    return _values[locale.languageCode]?[key] ?? _values['en']![key]!;
  }

  String get appName => text('appName');
  String get tagline => text('tagline');
  String get home => text('home');
  String get usb => text('usb');
  String get export => text('export');
  String get import => text('import');
  String get history => text('history');
  String get search => text('search');
  String get settings => text('settings');
  String get mobile => text('mobile');
  String get windows => text('windows');
  String get selectPhotos => text('selectPhotos');
  String get selectVideos => text('selectVideos');
  String get selectFiles => text('selectFiles');
  String get exportToUsb => text('exportToUsb');
  String get folderPlan => text('folderPlan');
  String get selectedItems => text('selectedItems');
  String get fileCounts => text('fileCounts');
  String get importFiles => text('importFiles');
  String get usbDestination => text('usbDestination');
  String get chooseDrive => text('chooseDrive');
  String get windowsImport => text('windowsImport');
  String get detectDrive => text('detectDrive');
  String get driveReady => text('driveReady');
  String get language => text('language');
  String get systemLanguage => text('systemLanguage');
  String get english => text('english');
  String get chinese => text('chinese');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((supported) => supported.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = isSupported(locale) ? locale.languageCode : 'en';
    return AppLocalizations(Locale(languageCode));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
