// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart' show Offset, Rect, TextRange;

/// Details of a string
@immutable
class StringDetails {
  /// List of words in the string
  final List<Word> words;
  /// Offset of canvas
  final Offset offset;

  const StringDetails({
    required this.words,
    required this.offset,
  });
}

@immutable
class Word {
  final String word;
  final Rect rect;
  final TextRange range;

  const Word({
    required this.word,
    required this.rect,
    required this.range,
  });

  Word copyWith({
    String? word,
    Rect? rect,
    TextRange? range,
  }) {
    return Word(
      word: word ?? this.word,
      rect: rect ?? this.rect,
      range: range ?? this.range,
    );
  }
}
