import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:myhealth/constants.dart';
import 'package:tap_debouncer/tap_debouncer.dart';
import 'package:path/path.dart' as p;

enum WhyFarther { harder, smarter, selfStarter, tradingCharter }

class AddHealthRecordEntryScreen extends StatefulWidget {
  final File data;
  const AddHealthRecordEntryScreen({Key? key, required this.data})
      : super(key: key);
  @override
  _AddHealthRecordEntryScreenState createState() =>
      _AddHealthRecordEntryScreenState();
}

class _AddHealthRecordEntryScreenState
    extends State<AddHealthRecordEntryScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final database = FirebaseDatabase.instance.ref();
  List<TextEditingController> keyControllers =
      List.generate(0, (i) => TextEditingController());
  List<TextEditingController> valueControllers =
      List.generate(0, (i) => TextEditingController());

  bool customField = false;
  int numberCustomField = 0;
  late WhyFarther _selection;

  @override
  Widget build(BuildContext context) {
    File filePicked = widget.data;

    final TextEditingController nameController = new TextEditingController();
    final nameField = TextFormField(
      autofocus: false,
      controller: nameController,
      keyboardType: TextInputType.text,
      style: TextStyle(color: kBlack),
      validator: (value) {
        if (value!.isEmpty) {
          return ("Mohon nama rekam medis anda.");
        }
        return null;
      },
      onSaved: (value) {
        nameController.text = value!;
      },
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.description_outlined,
          color: kBlack,
        ),
        hintText: "Nama",
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "Nama",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );

    DateTime selectedDate = DateTime.now();
    final TextEditingController dateController = new TextEditingController(
        text: "${selectedDate.toLocal()}"
            .split(' ')[0]); //"${selectedDate.toLocal()}".split(' ')[0]
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(1900, 1),
          lastDate: DateTime.now());
      if (picked != null && picked != selectedDate) {
        selectedDate = picked;
      }
      dateController.text = "${selectedDate.toLocal()}".split(' ')[0];
    }

    final dateField = TextFormField(
      autofocus: false,
      controller: dateController,
      showCursor: true,
      readOnly: true,
      style: TextStyle(color: kBlack),
      validator: (value) {
        if (value!.isEmpty) {
          return ("Masukkan tanggal rekam medis.");
        }

        return null;
      },
      onTap: () => _selectDate(context),
      onSaved: (value) {
        dateController.text = value!;
      },
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.date_range_outlined,
          color: kBlack,
        ),
        hintText: "Tanggal",
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "Tanggal",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );

    final TextEditingController locationController =
        new TextEditingController();
    final locationField = TextFormField(
      autofocus: false,
      controller: locationController,
      keyboardType: TextInputType.text,
      style: TextStyle(color: kBlack),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.location_on_outlined,
          color: kBlack,
        ),
        hintText: "Lokasi",
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "Lokasi",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
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
        hintText: "Deskripsi",
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "Deskripsi",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );

    final TextEditingController tagController = new TextEditingController();
    final tagField = TextFormField(
      autofocus: false,
      controller: tagController,
      keyboardType: TextInputType.text,
      style: TextStyle(color: kBlack),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.tag,
          color: kBlack,
        ),
        hintText: "Tag",
        hintStyle: TextStyle(color: Colors.black54),
        border: InputBorder.none,
        labelText: "Tag",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );

    Future<bool> uploadHealthRecord() async {
      try {
        DatabaseReference pushIDref =
            database.child("health-record").child(user.uid).push();
        String uniquePushID = pushIDref.key!;
        Reference healthRecordref = FirebaseStorage.instance
            .ref()
            .child('health-record')
            .child(uniquePushID)
            .child('/' + uniquePushID);

        try {
          await healthRecordref.putData(await filePicked.readAsBytes());
        } catch (e) {
          print(e);
          try {
            await healthRecordref.putFile(File(filePicked.path));
          } catch (e) {
            print(e);
            return false;
          }
        }

        try {
          await pushIDref.update({
            "creationdate": dateController.text,
            "description": descriptionController.text,
            "location": locationController.text,
            "name": nameController.text,
            "tag": tagController.text,
            "filename": p.basename(filePicked.path),
          });
          for (int i = 0; i < numberCustomField; i++) {
            await pushIDref
                .update({keyControllers[i].text: valueControllers[i].text});
          }
        } catch (e) {
          print(e);
          return false;
        }
        return true;
      } catch (e) {
        print(e);
        return false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kLightBlue1,
        title: Text("Rekam Medis Baru"),
        actions: <Widget>[
          PopupMenuButton<WhyFarther>(
            onSelected: (WhyFarther result) {
              setState(() {
                _selection = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<WhyFarther>>[
              const PopupMenuItem<WhyFarther>(
                value: WhyFarther.harder,
                child: Text('Working a lot harder'),
              ),
              const PopupMenuItem<WhyFarther>(
                value: WhyFarther.smarter,
                child: Text('Being a lot smarter'),
              ),
              const PopupMenuItem<WhyFarther>(
                value: WhyFarther.selfStarter,
                child: Text('Being a self-starter'),
              ),
              const PopupMenuItem<WhyFarther>(
                value: WhyFarther.tradingCharter,
                child: Text('Placed in charge of trading charter'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.extension(filePicked.path) == ".jpg" ||
                    p.extension(filePicked.path) == ".png")
                  Container(
                    child: Column(
                      children: [
                        Image.file(
                          filePicked,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  )
                else
                  Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'File dengan nama ${p.basename(filePicked.path)} terpilih.',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      )),
                SizedBox(
                  height: 10,
                ),
                Divider(
                  color: Colors.black54,
                ),
                dateField,
                nameField,
                locationField,
                descriptionField,
                tagField,
                Divider(
                  color: Colors.black54,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 10, bottom: 5),
                  child: Text(
                    'Kolom Kustom',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: kLightBlue1,
                      fontSize: 18,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (customField)
                  for (int i = 0; i < numberCustomField; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              autofocus: false,
                              controller: keyControllers[i],
                              keyboardType: TextInputType.text,
                              style: TextStyle(color: kBlack),
                              decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.black54),
                                border: InputBorder.none,
                                labelText: "Key" + (i + 1).toString(),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: TextFormField(
                              maxLines: null,
                              autofocus: false,
                              controller: valueControllers[i],
                              keyboardType: TextInputType.text,
                              style: TextStyle(color: kBlack),
                              decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.black54),
                                border: InputBorder.none,
                                labelText: "Value" + (i + 1).toString(),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                              ),
                            ),
                          ),
                          IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity:
                                  VisualDensity(horizontal: -4, vertical: -4),
                              onPressed: () {
                                setState(() {
                                  keyControllers.removeAt(i);
                                  valueControllers.removeAt(i);
                                  numberCustomField -= 1;
                                  if (numberCustomField == 0) {
                                    customField = false;
                                  }
                                });
                              },
                              icon: Icon(
                                Icons.remove,
                                color: Colors.black45,
                                size: 16,
                              )),
                        ],
                      ),
                    ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      keyControllers.add(TextEditingController());
                      valueControllers.add(TextEditingController());
                      customField = true;
                      numberCustomField += 1;
                    });
                  },
                  child: Text(
                    "Tambahkan kolom kustom",
                    style: TextStyle(color: kWhite),
                  ),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(kLightBlue1)),
                ),
                Divider(
                  color: Colors.black54,
                ),
                TapDebouncer(
                  onTap: () async {
                    final snackBar = SnackBar(
                      content: const Text("Sedang memuat...",
                          style: TextStyle(color: Colors.black)),
                      backgroundColor: kYellow,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    bool stateUpload = await uploadHealthRecord();
                    if (stateUpload) {
                      Navigator.of(context).pop();
                    } else {
                      final snackBar = SnackBar(
                        content: const Text(
                            "Upload gagal, cek koneksi internet.",
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
      ),
    );
  }
}