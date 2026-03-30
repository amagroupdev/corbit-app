/// Model representing a single chunk of RAG (Retrieval-Augmented Generation)
/// data loaded from local Markdown files.
///
/// Each chunk corresponds to a section within a Markdown file, split by
/// `##` headings. The chunk is used for context injection into the AI
/// assistant's system prompt.
class RagChunkModel {
  const RagChunkModel({
    required this.id,
    required this.source,
    required this.title,
    required this.content,
    this.keywords = const [],
  });

  /// Unique identifier for this chunk (e.g. "filename_0").
  final String id;

  /// The source filename this chunk was extracted from.
  final String source;

  /// The heading/title of this section.
  final String title;

  /// The body content of this section.
  final String content;

  /// Keywords associated with this chunk for search scoring.
  final List<String> keywords;

  // ─── JSON ───────────────────────────────────────────────────────────────

  factory RagChunkModel.fromJson(Map<String, dynamic> json) {
    return RagChunkModel(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'title': title,
      'content': content,
      'keywords': keywords,
    };
  }

  @override
  String toString() => 'RagChunkModel(id: $id, title: $title)';
}
