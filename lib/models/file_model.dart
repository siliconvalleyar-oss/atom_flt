class FileModel {
  final String? path;
  final String name;
  final String content;
  final bool isModified;

  FileModel({
    this.path,
    required this.name,
    required this.content,
    this.isModified = false,
  });

  FileModel copyWith({
    String? path,
    String? name,
    String? content,
    bool? isModified,
  }) {
    return FileModel(
      path: path ?? this.path,
      name: name ?? this.name,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
    );
  }
}
