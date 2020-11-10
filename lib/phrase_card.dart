import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lipspeak/model/phrase_book.dart';
import 'package:lipspeak/speech_generator.dart';
import 'package:lipspeak/util/colors.dart';

class PhraseCard extends StatelessWidget {
  final QuerySnapshot snapshot;
  final int index;
  final SpeechGenerator speechGen;
  const PhraseCard({Key key, this.snapshot, this.index, this.speechGen})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var snapshotData = snapshot.docs[index].data();
    var docId = snapshot.docs[index].id;
    var collectionReference =
        FirebaseFirestore.instance.collection(PhraseFS.fbCollectionName);

    TextEditingController queryInputController =
        TextEditingController(text: snapshotData[PhraseFS.fbQueryFieldName]);
    TextEditingController textInputController =
        TextEditingController(text: snapshotData[PhraseFS.fbTextFieldName]);

    return Column(
      children: [
        Container(
          height: 130,
          child: Card(
            elevation: 9,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    "${snapshotData[PhraseFS.fbQueryFieldName]}",
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                  ),
                  subtitle: Text(
                    snapshotData[PhraseFS.fbTextFieldName],
                    style: TextStyle(fontSize: 18),
                  ),
                  leading: IconButton(
                      icon: Icon(
                        Icons.mic,
                        size: 40,
                        color: primaryIndigoDark,
                      ),
                      onPressed: () {
                        speechGen.speakPhrase(
                            snapshotData[PhraseFS.fbTextFieldName]);
                      }),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 25,
                          color: primaryIndigoDark,
                        ),
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              child: AlertDialog(
                                contentPadding: EdgeInsets.all(10),
                                content: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(30.0),
                                      child: Text("Update the Phrase:",
                                          style: TextStyle(
                                              color: Colors.indigo.shade900,
                                              fontSize: 24)),
                                    ),
                                    Expanded(
                                        child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        autofocus: true,
                                        autocorrect: true,
                                        decoration: InputDecoration(
                                          icon:
                                              Icon(Icons.camera_front_outlined),
                                          labelText: "Keyword(s)",
                                          labelStyle: TextStyle(fontSize: 20),
                                        ),
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
                                          icon: Icon(
                                            Icons.mic_outlined,
                                          ),
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
                                        // nameInputController.clear();
                                        // titleInputController.clear();
                                        // descriptionInputController.clear();

                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "CANCEL",
                                        style: TextStyle(
                                            color: primaryIndigoDark,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      )),
                                  FlatButton(
                                      onPressed: () {
                                        if (queryInputController
                                                .text.isNotEmpty &&
                                            textInputController
                                                .text.isNotEmpty) {
                                          collectionReference
                                              .doc(docId)
                                              .update({
                                            PhraseFS.fbQueryFieldName:
                                                queryInputController.text,
                                            PhraseFS.fbTextFieldName:
                                                textInputController.text
                                          }).then((response) {
                                            Navigator.pop(context);
                                          });
                                        }
                                      },
                                      child: Text(
                                        "UPDATE",
                                        style: TextStyle(
                                            color: primaryIndigoDark,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ))
                                ],
                              ));
                        }),
                    SizedBox(
                      height: 19,
                    ),
                    IconButton(
                        icon: Icon(
                          Icons.delete_forever_outlined,
                          size: 25,
                          color: primaryIndigoDark,
                        ),
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Delete Phrase?'),
                                  content: Text(
                                      'This will permanently delete the phrase from your phrasebook. Are you sure you want to proceed?'),
                                  actions: [
                                    FlatButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('CANCEL',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: primaryIndigoDark,
                                                fontWeight: FontWeight.bold))),
                                    FlatButton(
                                        onPressed: () {
                                          collectionReference
                                              .doc(docId)
                                              .delete()
                                              .then((response) {
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: const Text('DELETE',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: primaryIndigoDark,
                                                fontWeight: FontWeight.bold)))
                                  ],
                                );
                              });
                        })
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
