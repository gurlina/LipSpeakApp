import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lipspeak/model/phrase_book.dart';
import 'package:lipspeak/speech_generator.dart';

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
                        ),
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              child: AlertDialog(
                                contentPadding: EdgeInsets.all(10),
                                content: Column(
                                  children: [
                                    Text("Please fill out the form to update."),
                                    Expanded(
                                        child: TextField(
                                      autofocus: true,
                                      autocorrect: true,
                                      decoration: InputDecoration(
                                          labelText: "Keyword(s):"),
                                      controller: queryInputController,
                                    )),
                                    Expanded(
                                        child: TextField(
                                      autofocus: true,
                                      autocorrect: true,
                                      decoration: InputDecoration(
                                          labelText: "Generated phrase:"),
                                      controller: textInputController,
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
                                      child: Text("Cancel")),
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
                                      child: Text("Update"))
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
                        ),
                        onPressed: () async {
                          await collectionReference.doc(docId).delete();
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
