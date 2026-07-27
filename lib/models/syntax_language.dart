class SyntaxLanguage {
  SyntaxLanguage._();

  static const Map<String, String> _extensionMap = {
    '.dart': 'dart',
    '.py': 'python',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.cpp': 'cpp',
    '.hpp': 'cpp',
    '.h': 'c',
    '.c': 'c',
    '.cs': 'csharp',
    '.java': 'java',
    '.html': 'html',
    '.css': 'css',
    '.json': 'json',
    '.xml': 'xml',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.md': 'markdown',
    '.sh': 'bash',
    '.txt': 'plaintext',
    '.rb': 'ruby',
    '.php': 'php',
    '.rs': 'rust',
    '.go': 'go',
    '.kt': 'kotlin',
    '.swift': 'swift',
    '.sql': 'sql',
  };

  static String? detect(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot == -1) return null;
    final ext = name.substring(dot).toLowerCase();
    return _extensionMap[ext];
  }
}
