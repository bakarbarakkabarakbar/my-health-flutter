import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:myhealth/components/generate.dart';
import 'package:myhealth/components/health_record.dart';
import 'package:myhealth/constants.dart';
import 'package:myhealth/screens/qr_code_scanner_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tap_debouncer/tap_debouncer.dart';

class AddEntryHealthRecordAccessScreen extends StatefulWidget {
  const AddEntryHealthRecordAccessScreen({Key? key}) : super(key: key);
  @override
  _AddEntryHealthRecordAccessScreenState createState() =>
      _AddEntryHealthRecordAccessScreenState();
}

class _AddEntryHealthRecordAccessScreenState
    extends State<AddEntryHealthRecordAccessScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final database = FirebaseDatabase.instance.ref();
  final storage = FirebaseStorage.instance.ref();
  Directory? _externalDocumentsDirectory;
  final _formKey = GlobalKey<FormState>();
  String dropdownValue = '';
  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final TextEditingController dateController = new TextEditingController(
        text: "${selectedDate.toLocal()}"
            .split(' ')[0]); //"${selectedDate.toLocal()}".split(' ')[0]

    final dateField = TextFormField(
      enabled: false,
      autofocus: false,
      controller: dateController,
      readOnly: true,
      style: TextStyle(color: kBlack),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.date_range_outlined,
          color: kBlack,
        ),
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "Tanggal",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );

    final TextEditingController userIDController = new TextEditingController();
    final userIDField = TextFormField(
      enabled: true,
      autofocus: false,
      controller: userIDController,
      keyboardType: TextInputType.text,
      style: TextStyle(color: kBlack),
      validator: (value) {
        RegExp regex = new RegExp(r'^.{28,}$');
        if (!regex.hasMatch(value!)) {
          return ('');
        }
        return null;
      },
      onSaved: (value) {
        userIDController.text = value!;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.perm_identity_outlined,
          color: kBlack,
        ),
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "User ID Partner",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        errorStyle: TextStyle(height: 0),
      ),
    );

    final TextEditingController descriptionController =
        new TextEditingController();
    final descriptionField = TextFormField(
      maxLines: null,
      autofocus: false,
      controller: descriptionController,
      keyboardType: TextInputType.text,
      style: TextStyle(color: kBlack),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.list_alt_outlined,
          color: kBlack,
        ),
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "Catatan",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kLightBlue1,
        title: Text("Entry Baru"),
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          SizedBox(
            height: 24,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 12),
            child: Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: kLightBlue1,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Punya kode QR partner?",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Row(
            children: [
              SizedBox(
                width: 56,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => qrCodeScannerScreen()));
                },
                child: Text(
                  "QR Scanner",
                  style: TextStyle(color: kWhite),
                ),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(kLightBlue1)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Column(
                      children: [
                        Divider(
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  dateField,
                  userIDField,
                  descriptionField,
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Column(
                      children: [
                        Divider(
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  TapDebouncer(
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        bool result = false;
                        try {
                          final snackBar = SnackBar(
                            content: const Text("Memuat...",
                                style: TextStyle(color: Colors.black)),
                            backgroundColor: kYellow,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          _externalDocumentsDirectory =
                              await getExternalStorageDirectory();
                          File fileToHealthRecordAccess = File(
                              "${_externalDocumentsDirectory!.path}/Akses Rekam Medis/${user.uid}");

                          await storage
                              .child('health-record-access')
                              .child(user.uid)
                              .writeToFile(fileToHealthRecordAccess);

                          String healthRecordAccessRaw =
                              fileToHealthRecordAccess.readAsStringSync();
                          print(healthRecordAccessRaw);
                          AccessEntryBlockChain healthRecordAccess =
                              AccessEntryBlockChain.fromJson(
                                  jsonDecode(healthRecordAccessRaw));
                          healthRecordAccess.data.add(
                            AccessEntry(generateRandomString(10),
                                entryType: "request",
                                enabled: true,
                                uid: userIDController.text,
                                hash: sha256
                                    .convert(utf8.encode(healthRecordAccess
                                        .data.last
                                        .toJson()
                                        .toString()))
                                    .toString(),
                                date:
                                    "${DateTime.now().toLocal()}".split(' ')[0],
                                notes: descriptionController.text),
                          );
                          healthRecordAccess.data.add(
                            AccessEntry(generateRandomString(10),
                                entryType: "permit",
                                enabled: true,
                                uid: userIDController.text,
                                hash: sha256
                                    .convert(utf8.encode(healthRecordAccess
                                        .data.last
                                        .toJson()
                                        .toString()))
                                    .toString(),
                                date:
                                    "${DateTime.now().toLocal()}".split(' ')[0],
                                notes: descriptionController.text),
                          );

                          fileToHealthRecordAccess.writeAsString(
                              jsonEncode(healthRecordAccess.toJson()));
                          Reference healthRecordAccessref = FirebaseStorage
                              .instance
                              .ref()
                              .child('health-record-access')
                              .child(user.uid);

                          try {
                            await healthRecordAccessref.putData(
                                await fileToHealthRecordAccess.readAsBytes());
                            result = true;
                          } catch (e) {
                            print(e);
                            try {
                              await healthRecordAccessref
                                  .putFile(File(fileToHealthRecordAccess.path));
                              result = true;
                            } catch (e) {
                              print(e);
                            }
                          }
                        } catch (e) {
                          print(e);
                        }
                        if (result) {
                          final snackBar = SnackBar(
                            content: const Text("Berhasil.",
                                style: TextStyle(color: Colors.black)),
                            backgroundColor: kYellow,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          Navigator.of(context).pop();
                        } else {
                          final snackBar = SnackBar(
                            content: const Text("Gagal, cek koneksi anda.",
                                style: TextStyle(color: Colors.black)),
                            backgroundColor: kYellow,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      } else {
                        final snackBar = SnackBar(
                          content: const Text("Form tidak valid.",
                              style: TextStyle(color: Colors.black)),
                          backgroundColor: kYellow,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    builder: (BuildContext context, TapDebouncerFunc? onTap) {
                      return InkWell(
                        onTap: onTap,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 80,
                              width: 80,
                              child: Card(
                                color: kWhite,
                                elevation: 4,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.check_box_outlined,
                                      color: kBlack,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selesai dan Upload',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "Pastikan data yang dimasukkan telah benar. ",
                                    style: TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}
