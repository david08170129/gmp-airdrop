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
      'wirelessReceiveAndroidSubtitle':
          'Scan the QR code with iPhone Safari to upload directly to this Android device over the same local Wi-Fi network.',
      'wirelessReceiveWindowsSubtitle':
          'Scan the QR code with iPhone Safari or Android Chrome to upload directly to this Windows PC over the same local Wi-Fi network.',
      'wirelessReceiveLive': 'Wireless receive is live',
      'startLocalReceiveServer': 'Start local receive server',
      'receiveProgress': 'Receive progress',
      'waitingForNextUpload': 'Waiting for the next upload',
      'noUploadsYet': 'No uploads yet',
      'liveActivityWillAppear':
          'Live activity will appear here as files arrive.',
      'startReceivingToShowActivity':
          'Start receiving to show wireless transfer activity.',
      'receivedFiles': 'Received Files',
      'appStorageWirelessPhotos': 'App storage/GMP_Airdrop/Wireless/Photos',
      'dropFiles': 'Drop files',
      'receivingFiles': 'Receiving files...',
      'readyToReceiveFiles': 'Ready to receive files',
      'releaseAnywhere': 'Release anywhere',
      'windowsLocalDropReady': 'Windows local drop ready',
      'networkMode': 'Network mode',
      'localReceiveServerActive': 'Local receive server active',
      'serverStopped': 'Server stopped',
      'releaseToSave': 'Release to save',
      'filesWillLandWirelessFolders':
          'Files will land in the same wireless folders.',
      'androidIp': 'Android IP',
      'pcIpAddress': 'PC IP address',
      'receiveUrl': 'Receive URL',
      'available': 'Available',
      'stopReceiving': 'Stop receiving',
      'starting': 'Starting...',
      'startWirelessReceive': 'Start wireless receive',
      'unknown': 'Unknown',
      'saved': 'saved',
      'receiving': 'receiving',
      'couldNotStartWirelessReceive': 'Could not start wireless receive',
      'transferComplete': 'Transfer complete',
      'filesReceived': 'files received',
      'couldNotSaveDroppedFiles': 'Could not save dropped files',
      'sendToPhoneTitle': 'Send to Phone',
      'sendToPhoneSubtitle':
          'Share selected Android photos, videos, and files to iPhone Safari over the same local Wi-Fi network.',
      'openingAndroidFilePicker': 'Opening Android file picker...',
      'noFilesSelected': 'No files selected',
      'filesSelected': 'file(s) selected',
      'couldNotSelectFiles': 'Could not select files.',
      'preparingLocalShare': 'Preparing local share...',
      'filesReadyForIphoneDownload': 'file(s) ready for iPhone download',
      'couldNotPrepareFilesForSharing': 'Could not prepare files for sharing.',
      'couldNotStartPhoneShare': 'Could not start phone share',
      'phoneShareStopped': 'Phone share stopped',
      'sendToPhoneAndroidOnly': 'Send to Phone runs from the Android app.',
      'iphoneDownloadPageLive': 'iPhone download page is live',
      'androidLocalShare': 'Android local share',
      'downloadUrl': 'Download URL',
      'refreshShare': 'Refresh share',
      'startPhoneShare': 'Start phone share',
      'stopSharing': 'Stop sharing',
      'filesOnDownloadPage': 'file(s) on download page',
      'chooseFilesFromAndroid': 'Choose files from Android',
      'files': 'Files',
      'downloadActivity': 'Download activity',
      'waitingForIphoneDownloads': 'Waiting for iPhone downloads',
      'noSharedFilesYet': 'No shared files yet',
      'selectedFilesAppearBeforeQr':
          'Selected files will appear here before you show the QR code.',
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
      'wirelessReceiveAndroidSubtitle':
          '使用 iPhone Safari 扫描二维码，通过同一 Wi-Fi 直接上传到这台 Android 设备。',
      'wirelessReceiveWindowsSubtitle':
          '使用 iPhone Safari 或 Android Chrome 扫描二维码，通过同一 Wi-Fi 直接上传到这台 Windows 电脑。',
      'wirelessReceiveLive': '无线接收已开启',
      'startLocalReceiveServer': '启动本地接收服务',
      'receiveProgress': '接收进度',
      'waitingForNextUpload': '等待下一次上传',
      'noUploadsYet': '暂无上传',
      'liveActivityWillAppear': '文件到达时会在这里显示实时进度。',
      'startReceivingToShowActivity': '启动接收后会显示无线传输活动。',
      'receivedFiles': '已接收文件',
      'appStorageWirelessPhotos': '应用存储/GMP_Airdrop/Wireless/Photos',
      'dropFiles': '拖放文件',
      'receivingFiles': '正在接收文件...',
      'readyToReceiveFiles': '已准备接收文件',
      'releaseAnywhere': '松开即可保存',
      'windowsLocalDropReady': 'Windows 本地拖放已就绪',
      'networkMode': '网络模式',
      'localReceiveServerActive': '本地接收服务已开启',
      'serverStopped': '服务已停止',
      'releaseToSave': '松开保存',
      'filesWillLandWirelessFolders': '文件会保存到相同的无线接收文件夹。',
      'androidIp': 'Android IP',
      'pcIpAddress': '电脑 IP 地址',
      'receiveUrl': '接收链接',
      'available': '可用空间',
      'stopReceiving': '停止接收',
      'starting': '正在启动...',
      'startWirelessReceive': '开始无线接收',
      'unknown': '未知',
      'saved': '已保存',
      'receiving': '接收中',
      'couldNotStartWirelessReceive': '无法启动无线接收',
      'transferComplete': '传输完成',
      'filesReceived': '个文件已接收',
      'couldNotSaveDroppedFiles': '无法保存拖放文件',
      'sendToPhoneTitle': '发送到手机',
      'sendToPhoneSubtitle': '通过同一局域网，将 Android 上选中的照片、视频和文件分享给 iPhone Safari。',
      'openingAndroidFilePicker': '正在打开 Android 文件选择器...',
      'noFilesSelected': '未选择文件',
      'filesSelected': '个文件已选择',
      'couldNotSelectFiles': '无法选择文件。',
      'preparingLocalShare': '正在准备本地分享...',
      'filesReadyForIphoneDownload': '个文件已准备好供 iPhone 下载',
      'couldNotPrepareFilesForSharing': '无法准备分享文件。',
      'couldNotStartPhoneShare': '无法启动手机分享',
      'phoneShareStopped': '手机分享已停止',
      'sendToPhoneAndroidOnly': '发送到手机功能需要在 Android 应用中使用。',
      'iphoneDownloadPageLive': 'iPhone 下载页面已开启',
      'androidLocalShare': 'Android 本地分享',
      'downloadUrl': '下载链接',
      'refreshShare': '刷新分享',
      'startPhoneShare': '开始手机分享',
      'stopSharing': '停止分享',
      'filesOnDownloadPage': '个文件在下载页面',
      'chooseFilesFromAndroid': '从 Android 选择文件',
      'files': '文件',
      'downloadActivity': '下载活动',
      'waitingForIphoneDownloads': '等待 iPhone 下载',
      'noSharedFilesYet': '暂无分享文件',
      'selectedFilesAppearBeforeQr': '显示二维码前，已选择的文件会出现在这里。',
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
