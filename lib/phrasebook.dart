import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lipspeak/model/phrase_book.dart';
import 'package:lipspeak/phrase_card.dart';
import 'package:lipspeak/speech_generator.dart';

class PhraseBook extends StatefulWidget {
  PhraseBook({Key key}) : super(key: key);

  @override
  _PhraseBookState createState() => _PhraseBookState();
}

class _PhraseBookState extends State<PhraseBook> {
  var firestoreDb = FirebaseFirestore.instance
      .collection(PhraseFS.fbCollectionName)
      .snapshots();
  TextEditingController queryInputController;
  TextEditingController textInputController;

  @override
  void initState() {
    super.initState();

    queryInputController = new TextEditingController();
    textInputController = new TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    SpeechGenerator speechGen = SpeechGenerator();
    return Scaffold(
      appBar: AppBar(
        title: Text("Phrasebook"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDialog(context);
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: StreamBuilder(
          stream: firestoreDb,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            } else {
              return ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, int index) {
                    return PhraseCard(
                      snapshot: snapshot.data,
                      index: index,
                      speechGen: speechGen,
                    );
                    //return Text(snapshot.data.documents[index]['text']);
                  });
            }
          }),
    );
  }

  _showDialog(BuildContext context) async {
    await showDialog(
        context: context,
        child: AlertDialog(
          contentPadding: EdgeInsets.all(10),
          content: Column(
            children: [
              Text("Add new entry to the phrasebook:"),
              Expanded(
                  child: TextField(
                autofocus: true,
                autocorrect: true,
                decoration: InputDecoration(
                    icon: Icon(Icons.camera_front_outlined),
                    labelText: "Keyword(s)",
                    helperText: "separate multiple keywords with spaces",
                    helperMaxLines: 3),
                controller: queryInputController,
              )),
              Expanded(
                  child: TextField(
                autofocus: true,
                autocorrect: true,
                decoration: InputDecoration(
                  icon: Icon(Icons.mic_outlined),
                  labelText: "Generated phrase",
                ),
                controller: textInputController,
              )),
            ],
          ),
          actions: [
            FlatButton(
                onPressed: () {
                  queryInputController.clear();
                  textInputController.clear();

                  Navigator.pop(context);
                },
                child: Text("Cancel")),
            FlatButton(
                onPressed: () {
                  if (queryInputController.text.isNotEmpty &&
                      textInputController.text.isNotEmpty) {
                    FirebaseFirestore.instance
                        .collection(PhraseFS.fbCollectionName)
                        .add({
                      PhraseFS.fbQueryFieldName: queryInputController.text,
                      PhraseFS.fbTextFieldName: textInputController.text,
                    }).then((response) {
                      //print(response.id);

                      Navigator.pop(context);

                      queryInputController.clear();
                      textInputController.clear();
                    }).catchError((error) => print(error));
                  }
                },
                child: Text("Save"))
          ],
        ));
  }
}
