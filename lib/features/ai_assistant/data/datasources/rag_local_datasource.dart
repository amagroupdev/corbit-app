import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/ai_assistant/data/models/rag_chunk_model.dart';

/// Local RAG datasource that loads and searches Markdown knowledge files
/// bundled in `assets/rag/`.
///
/// On [initialize], all Markdown files are loaded and split into chunks
/// by `##` headings. Each chunk is scored during [search] using simple
/// keyword matching against its title, content, and keywords list.
class RagLocalDatasource {
  RagLocalDatasource();

  /// All loaded chunks from the RAG Markdown files.
  final List<RagChunkModel> _chunks = [];

  /// Cached system prompt text loaded from `assets/prompts/system_prompt.txt`.
  String _systemPrompt = '';

  /// Cached navigation map JSON string.
  String _navigationMap = '';

  /// Whether [initialize] has been called successfully.
  bool _initialized = false;

  /// Returns the loaded system prompt text.
  String get systemPrompt => _systemPrompt;

  /// Returns the loaded navigation map JSON string.
  String get navigationMap => _navigationMap;

  /// Whether the datasource has been initialised.
  bool get isInitialized => _initialized;

  // ─── Common Arabic Stop Words ───────────────────────────────────────────

  /// Arabic stop words filtered out during keyword extraction.
  static const Set<String> _arabicStopWords = {
    'في', 'من', 'على', 'إلى', 'عن', 'مع', 'هذا', 'هذه', 'ذلك',
    'تلك', 'التي', 'الذي', 'هو', 'هي', 'هم', 'أن', 'لا', 'ما',
    'كان', 'كانت', 'يكون', 'بين', 'حتى', 'قد', 'لم', 'لن', 'ثم',
    'أو', 'و', 'ف', 'ب', 'ل', 'ك', 'ال', 'عند', 'كل', 'بعد',
    'قبل', 'أي', 'بعض', 'غير', 'كذلك', 'أيضا',
    // English stop words that may appear in mixed queries.
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been',
    'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from',
    'and', 'or', 'not', 'it', 'this', 'that', 'i', 'how', 'what',
  };

  // ─── Initialise ─────────────────────────────────────────────────────────

  /// Loads all RAG Markdown files from `assets/rag/`, the system prompt
  /// from `assets/prompts/system_prompt.txt`, and the navigation map
  /// from `assets/rag/navigation_map.json`.
  ///
  /// Must be called once before [search] or [getNavigationMap].
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load the asset manifest to discover RAG files.
      // Use AssetManifest.bin (Flutter 3.x+) with fallback to .json.
      final assetBundle = rootBundle;
      final manifestMap = await _loadManifest(assetBundle);

      // Discover all assets/rag/*.md files from the manifest.
      final ragFiles = <String>[];
      for (final key in manifestMap.keys) {
        if (key.startsWith('assets/rag/') && key.endsWith('.md')) {
          ragFiles.add(key);
        }
      }

      // Load and parse each Markdown file into chunks.
      for (final filePath in ragFiles) {
        try {
          final content = await rootBundle.loadString(filePath);
          final fileName =
              filePath.split('/').last.replaceAll('.md', '');
          final chunks = _parseMarkdown(content, fileName);
          _chunks.addAll(chunks);
        } catch (_) {
          // Skip files that fail to load.
        }
      }

      // Load system prompt.
      try {
        _systemPrompt = await rootBundle
            .loadString('assets/prompts/system_prompt.txt');
      } catch (_) {
        _systemPrompt = '';
      }

      // Load navigation map.
      try {
        _navigationMap = await rootBundle
            .loadString('assets/rag/navigation_map.json');
      } catch (_) {
        _navigationMap = '{}';
      }

      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize RAG datasource: $e');
    }
  }

  // ─── Search ─────────────────────────────────────────────────────────────

  /// Searches loaded chunks for the given [query] using keyword scoring.
  ///
  /// Scoring rules:
  /// - **+3** for each keyword found in the chunk title
  /// - **+2** for each keyword found in the chunk keywords list
  /// - **+1** for each keyword found in the chunk content
  ///
  /// Returns the top [maxResults] chunks sorted by descending score.
  /// Only chunks with a score > 0 are returned.
  List<RagChunkModel> search(String query, {int maxResults = 5}) {
    if (_chunks.isEmpty || query.trim().isEmpty) return [];

    final queryKeywords = _extractKeywords(query);
    if (queryKeywords.isEmpty) return [];

    final scored = <_ScoredChunk>[];

    for (final chunk in _chunks) {
      int score = 0;
      final titleLower = chunk.title.toLowerCase();
      final contentLower = chunk.content.toLowerCase();
      final keywordsLower =
          chunk.keywords.map((k) => k.toLowerCase()).toList();

      for (final keyword in queryKeywords) {
        if (titleLower.contains(keyword)) score += 3;
        if (keywordsLower.any((k) => k.contains(keyword))) score += 2;
        if (contentLower.contains(keyword)) score += 1;
      }

      if (score > 0) {
        scored.add(_ScoredChunk(chunk: chunk, score: score));
      }
    }

    // Sort descending by score.
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored
        .take(maxResults)
        .map((s) => s.chunk)
        .toList();
  }

  /// Returns the navigation map JSON string.
  ///
  /// Must call [initialize] first.
  String getNavigationMap() => _navigationMap;

  // ─── Private Helpers ────────────────────────────────────────────────────

  /// Loads the asset manifest, trying AssetManifest.bin first (Flutter 3.x+),
  /// then falling back to AssetManifest.json for older versions.
  Future<Map<String, dynamic>> _loadManifest(AssetBundle bundle) async {
    // Try loading known RAG files directly (most reliable approach).
    const knownFiles = [
      'assets/rag/api_docs.md',
      'assets/rag/app_features.md',
      'assets/rag/company_info.md',
      'assets/rag/faq.md',
      'assets/rag/services.md',
      'assets/rag/troubleshooting.md',
    ];
    // Build a fake manifest from known files.
    final manifest = <String, dynamic>{};
    for (final f in knownFiles) {
      manifest[f] = <String>[f];
    }

    // Also try to load AssetManifest.json as fallback for discovery.
    try {
      final content = await bundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(content);
      if (decoded is Map) {
        manifest.addAll(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Ignore – we already have the known files.
    }

    return manifest;
  }

  /// Splits a Markdown document into [RagChunkModel] chunks by `##` headings.
  ///
  /// Each `##` heading becomes a chunk title; everything until the next `##`
  /// heading (or end of file) becomes the chunk content. Keywords are
  /// extracted from a `keywords:` line if present in the section.
  List<RagChunkModel> _parseMarkdown(String markdown, String source) {
    final chunks = <RagChunkModel>[];
    final lines = markdown.split('\n');

    String currentTitle = source;
    final contentBuffer = StringBuffer();
    List<String> currentKeywords = [];
    int chunkIndex = 0;

    for (final line in lines) {
      if (line.startsWith('## ')) {
        // Save the previous chunk (if it has content).
        if (contentBuffer.isNotEmpty) {
          chunks.add(RagChunkModel(
            id: '${source}_$chunkIndex',
            source: source,
            title: currentTitle,
            content: contentBuffer.toString().trim(),
            keywords: currentKeywords,
          ));
          chunkIndex++;
          contentBuffer.clear();
          currentKeywords = [];
        }
        currentTitle = line.substring(3).trim();
      } else if (line.trim().toLowerCase().startsWith('keywords:')) {
        // Parse inline keywords (e.g. "keywords: رسائل, قوالب, مجموعات")
        final keywordStr =
            line.substring(line.indexOf(':') + 1).trim();
        currentKeywords = keywordStr
            .split(',')
            .map((k) => k.trim())
            .where((k) => k.isNotEmpty)
            .toList();
      } else {
        contentBuffer.writeln(line);
      }
    }

    // Don't forget the last chunk.
    if (contentBuffer.isNotEmpty) {
      chunks.add(RagChunkModel(
        id: '${source}_$chunkIndex',
        source: source,
        title: currentTitle,
        content: contentBuffer.toString().trim(),
        keywords: currentKeywords,
      ));
    }

    return chunks;
  }

  /// Extracts search keywords from a query string.
  ///
  /// Splits by whitespace, lowercases, and removes stop words.
  List<String> _extractKeywords(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .where((w) => !_arabicStopWords.contains(w))
        .toList();
  }
}

/// Internal helper for scoring chunks during search.
class _ScoredChunk {
  const _ScoredChunk({required this.chunk, required this.score});
  final RagChunkModel chunk;
  final int score;
}

// ─── Provider ────────────────────────────────────────────────────────────────

final ragLocalDatasourceProvider = Provider<RagLocalDatasource>((ref) {
  return RagLocalDatasource();
});
