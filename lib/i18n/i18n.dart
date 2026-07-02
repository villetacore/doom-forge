import 'en.dart';
import 'ru.dart';
import 'uk.dart';
import 'de.dart';
import 'fr.dart';
import 'es.dart';
import 'it.dart';
import 'pt.dart';
import 'pl.dart';
import 'zh.dart';
import 'ja.dart';

class Lang {
  final String id;
  final String label;
  const Lang(this.id, this.label);
}

const List<Lang> kLanguages = [
  Lang('en', 'English'),
  Lang('ru', 'Русский'),
  Lang('uk', 'Українська'),
  Lang('de', 'Deutsch'),
  Lang('fr', 'Français'),
  Lang('es', 'Español'),
  Lang('it', 'Italiano'),
  Lang('pt', 'Português'),
  Lang('pl', 'Polski'),
  Lang('zh', '中文'),
  Lang('ja', '日本語'),
];

const Map<String, Map<String, String>> kDicts = {
  'en': en,
  'ru': ru,
  'uk': uk,
  'de': de,
  'fr': fr,
  'es': es,
  'it': it,
  'pt': pt,
  'pl': pl,
  'zh': zh,
  'ja': ja,
};

/// Translate a dotted key for a language, falling back to English then the key.
String tr(String lang, String key) => kDicts[lang]?[key] ?? en[key] ?? key;
