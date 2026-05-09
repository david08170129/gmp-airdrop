class GmpFolderStructure {
  static const root = 'GMP_Airdrop';
  static const photos = '$root/Photos';
  static const videos = '$root/Videos';
  static const pdf = '$root/Documents/PDF';
  static const word = '$root/Documents/Word';
  static const excel = '$root/Documents/Excel';
  static const ppt = '$root/Documents/PPT';
  static const markdown = '$root/Documents/Markdown';
  static const txt = '$root/Documents/TXT';
  static const python = '$root/Code/Python';
  static const others = '$root/Documents/Others';

  static const all = [
    photos,
    videos,
    pdf,
    word,
    excel,
    ppt,
    markdown,
    txt,
    python,
    others,
  ];

  static String folderForExtension(String extension) {
    final normalized = extension.toLowerCase().replaceFirst('.', '');
    return switch (normalized) {
      'jpg' ||
      'jpeg' ||
      'png' ||
      'gif' ||
      'webp' ||
      'heic' ||
      'heif' ||
      'bmp' ||
      'tif' ||
      'tiff' ||
      'raw' ||
      'dng' =>
        photos,
      'mp4' || 'mov' || 'm4v' || 'avi' || 'mkv' || 'webm' || 'wmv' || '3gp' =>
        videos,
      'pdf' => pdf,
      'doc' || 'docx' => word,
      'xls' || 'xlsx' || 'csv' => excel,
      'ppt' || 'pptx' => ppt,
      'md' || 'markdown' => markdown,
      'txt' => txt,
      'py' => python,
      _ => others,
    };
  }
}
