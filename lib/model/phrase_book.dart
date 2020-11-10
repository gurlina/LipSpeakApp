import 'package:cloud_firestore/cloud_firestore.dart';

class Phrase {
  String text;
  String queries;

  Phrase(this.text, this.queries);

  static List<Phrase> getPhraseBook() => [
        Phrase("I need to make an appointment", "appointment"),
        Phrase("I feel pain when swallowing", "pain swallowing"),
        Phrase("I have difficulty breathing", "difficulty breathing"),
        Phrase("I always feel tired", "always tired"),
        Phrase("I suffer from insomnia", "insomnia"),
        Phrase("I need a shirt with an open collar", "shirt open collar"),
        Phrase("I need a shower shield", "shower shield"),
        Phrase("I am allergic to peanuts", "allergic peanuts"),
        Phrase("Please help me carry my groceries", "carry groceries"),
        Phrase("I am a vegetarian", "vegetarian"),
        Phrase("Call an ambulance", "ambulance"),
        Phrase("I am feeling better", "feeling better"),
        Phrase("What do we have for dinner?", "dinner"),
        Phrase("I am diabetic", "diabetic"),
        Phrase("I am having a headache", "headache"),
        Phrase("This feels uncomfortable", "uncomfortable"),
      ];
}

class PhraseFS {
  String text;
  String queries;

  PhraseFS(this.text, this.queries);

  static const String fbCollectionName = "phrasebook";
  static const String fbQueryFieldName = "query";
  static const String fbTextFieldName = "text";

  static Future<List<PhraseFS>> getPhraseBook() async {
    List<PhraseFS> _phraseBook = new List<PhraseFS>();
    var fbCollection =
        await FirebaseFirestore.instance.collection(fbCollectionName).get();
    fbCollection.docs.forEach((res) {
      _phraseBook.add(
          PhraseFS(res.data()[fbTextFieldName], res.data()[fbQueryFieldName]));
    });

    if (_phraseBook.isNotEmpty) {
      _phraseBook.sort((a, b) => a.queries.compareTo(b.queries));
    }

    return _phraseBook;
  }
}
