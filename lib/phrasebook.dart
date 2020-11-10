import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lipspeak/model/phrase_book.dart';
import 'package:lipspeak/phrase_card.dart';
import 'package:lipspeak/speech_generator.dart';
import 'package:lipspeak/util/colors.dart';

class PhraseBook extends StatefulWidget {
  final SpeechGenerator speechGen;
  PhraseBook({Key key, this.speechGen}) : super(key: key);

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
    //SpeechGenerator speechGen = SpeechGenerator();
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
                      speechGen: widget.speechGen,
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
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Add New Phrase:",
                  style: TextStyle(color: Colors.indigo.shade900, fontSize: 24),
                ),
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  autofocus: true,
                  autocorrect: true,
                  maxLines: 2,
                  decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      icon: Icon(Icons.camera_front_outlined),
                      labelText: "Keyword(s)",
                      labelStyle: TextStyle(fontSize: 20),
                      hintText: "separate keywords with spaces",
                      hintStyle: TextStyle(color: Colors.indigo.shade100),
                      hintMaxLines: 2,
                      helperMaxLines: 3),
                  controller: queryInputController,
                ),
              )),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  autofocus: true,
                  autocorrect: true,
                  maxLines: 2,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    icon: Icon(Icons.mic_outlined),
                    labelText: "Generated Speech",
                    labelStyle: TextStyle(fontSize: 20),
                  ),
                  controller: textInputController,
                ),
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
                child: Text("Cancel",
                    style: TextStyle(
                        color: primaryIndigoDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))),
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
                child: Text("Save",
                    style: TextStyle(
                        color: primaryIndigoDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)))
          ],
        ));
  }
}
