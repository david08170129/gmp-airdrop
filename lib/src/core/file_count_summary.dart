class FileCountSummary {
  const FileCountSummary({
    required this.photos,
    required this.videos,
    required this.documents,
    required this.code,
  });

  final int photos;
  final int videos;
  final int documents;
  final int code;

  int get total => photos + videos + documents + code;

  static const empty = FileCountSummary(
    photos: 0,
    videos: 0,
    documents: 0,
    code: 0,
  );
}
