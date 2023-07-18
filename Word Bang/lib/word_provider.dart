  import 'dart:io';
  import 'package:flutter/services.dart';

  class WordProvider {
    Future<List<String>> loadWordList() async {
      final wordList =
      await rootBundle.loadString('assets/filtered_kelime_listesi.txt');
      return wordList
          .split('\n')
          .map((word) => word.trim()) // Her satırdaki fazlalık boşlukları kaldırır
          .where((word) => word.isNotEmpty)
          .toList();
    }

  }
