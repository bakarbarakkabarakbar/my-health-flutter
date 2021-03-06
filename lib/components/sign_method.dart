import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myhealth/components/health_record.dart';
import 'package:path_provider/path_provider.dart';

class SignProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _user;

  GoogleSignInAccount get user => _user!;

  Future<String> googleSignup() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "failed-to-sign";
      _user = googleUser;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      try {
        final user = FirebaseAuth.instance.currentUser!;
        final database = FirebaseDatabase.instance.ref();
        DataSnapshot checkEmail = await database.child("email").get();
        Directory? _externalDocumentsDirectory;
        if (!checkEmail.hasChild(user.uid)) {
          try {
            await database.update({
              "address/" + user.uid: "",
              "birthdate/" + user.uid: "",
              "birthplace/" + user.uid: "",
              "city/" + user.uid: "",
              "displayname/" + user.uid: RegExp(r"^([^@]+)")
                  .stringMatch(user.email.toString())
                  .toString(),
              "email/" + user.uid: user.email,
              "fullname/" + user.uid: "",
              "gender/" + user.uid: "",
              "job/" + user.uid: "",
              "nik/" + user.uid: "",
              "phonenumber/" + user.uid: "",
              "zipcode/" + user.uid: "",
              "photoprofile/" + user.uid:
                  "https://firebasestorage.googleapis.com/v0/b/myhealth-default-storage/o/blank_photo_profile.png?alt=media&token=b7c09a0d-cd6c-4514-9498-647b5df0bd28"
            });
            var accessEntry = AccessEntryBlockChain(user.uid);
            _externalDocumentsDirectory = await getExternalStorageDirectory();
            Directory('${_externalDocumentsDirectory!.path}/Akses Rekam Medis/')
                .createSync(recursive: true);

            File fileToHealthRecordAccess = File(
                "${_externalDocumentsDirectory.path}/Akses Rekam Medis/${user.uid}");

            fileToHealthRecordAccess
                .writeAsString(jsonEncode(accessEntry.toJson()));

            Reference healthRecordAccessref = FirebaseStorage.instance
                .ref()
                .child('health-record-access')
                .child(user.uid);

            try {
              await healthRecordAccessref
                  .putData(await fileToHealthRecordAccess.readAsBytes());
            } catch (e) {
              print(e.toString());
              try {
                await healthRecordAccessref
                    .putFile(File(fileToHealthRecordAccess.path));
              } catch (e) {
                print(e.toString());
                return e.toString();
              }
            }
          } catch (e) {
            print(e.toString());
            return e.toString();
          }
        }
        if (!user.emailVerified) {
          user.sendEmailVerification();
          await logout();
          return "email-not-verified";
        } else {
          notifyListeners();
          return "true";
        }
      } catch (e) {
        print(e.toString());
        return e.toString();
      }
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
  }

  Future<String> googleLogin() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "failed-to-sign";
      _user = googleUser;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      try {
        final user = FirebaseAuth.instance.currentUser!;
        final database = FirebaseDatabase.instance.ref();
        DataSnapshot checkEmail = await database.child("email").get();
        Directory? _externalDocumentsDirectory;
        if (!checkEmail.hasChild(user.uid)) {
          try {
            await database.update({
              "address/" + user.uid: "",
              "birthdate/" + user.uid: "",
              "birthplace/" + user.uid: "",
              "city/" + user.uid: "",
              "displayname/" + user.uid: RegExp(r"^([^@]+)")
                  .stringMatch(user.email.toString())
                  .toString(),
              "email/" + user.uid: user.email,
              "fullname/" + user.uid: "",
              "gender/" + user.uid: "",
              "job/" + user.uid: "",
              "nik/" + user.uid: "",
              "phonenumber/" + user.uid: "",
              "zipcode/" + user.uid: "",
              "photoprofile/" + user.uid:
                  "https://firebasestorage.googleapis.com/v0/b/myhealth-default-storage/o/blank_photo_profile.png?alt=media&token=b7c09a0d-cd6c-4514-9498-647b5df0bd28"
            });
            var accessEntry = AccessEntryBlockChain(user.uid);
            _externalDocumentsDirectory = await getExternalStorageDirectory();
            Directory('${_externalDocumentsDirectory!.path}/Akses Rekam Medis/')
                .createSync(recursive: true);

            File fileToHealthRecordAccess = File(
                "${_externalDocumentsDirectory.path}/Akses Rekam Medis/${user.uid}");

            fileToHealthRecordAccess
                .writeAsString(jsonEncode(accessEntry.toJson()));

            Reference healthRecordAccessref = FirebaseStorage.instance
                .ref()
                .child('health-record-access')
                .child(user.uid);

            try {
              await healthRecordAccessref
                  .putData(await fileToHealthRecordAccess.readAsBytes());
            } catch (e) {
              print(e.toString());
              try {
                await healthRecordAccessref
                    .putFile(File(fileToHealthRecordAccess.path));
              } catch (e) {
                print(e.toString());
                return e.toString();
              }
            }
          } catch (e) {
            print(e.toString());
            return e.toString();
          }
        }
        if (!user.emailVerified) {
          user.sendEmailVerification();
          await logout();
          return "email-not-verified";
        } else {
          notifyListeners();
          return "true";
        }
      } catch (e) {
        print(e.toString());
        return e.toString();
      }
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
  }

  Future<String> emailLogin(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = FirebaseAuth.instance.currentUser!;
      if (user.photoURL == null) {
        await user.updatePhotoURL(
            "https://firebasestorage.googleapis.com/v0/b/myhealth-default-storage/o/blank_photo_profile.png?alt=media&token=b7c09a0d-cd6c-4514-9498-647b5df0bd28");
      }
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      return e.code;
      // if (e.code == 'invalid-email') {
      //   SnackBar(content: const Text("Akun tidak terdaftar."));
      // } else if (e.code == 'user-not-found') {
      //   SnackBar(content: const Text("Akun tidak terdaftar."));
      // } else if (e.code == 'wrong-password') {
      //   SnackBar(content: const Text("Password salah."));
      // }
    } catch (e) {
      print(e.toString());
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      if (!user.emailVerified) {
        user.sendEmailVerification();
        await logout();
        return "email-not-verified";
      } else {
        notifyListeners();
      }
    } catch (e) {
      print(e.toString());
    }
    return "true";
  }

  Future<String> emailSignUp(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      try {
        final user = FirebaseAuth.instance.currentUser!;
        await user.updateDisplayName(
            RegExp(r"^([^@]+)").stringMatch(user.email.toString()).toString());
        await user.sendEmailVerification();
        final database = FirebaseDatabase.instance.ref();
        Directory? _externalDocumentsDirectory;
        try {
          await database.update({
            "address/" + user.uid: "",
            "birthdate/" + user.uid: "",
            "birthplace/" + user.uid: "",
            "city/" + user.uid: "",
            "displayname/" + user.uid: RegExp(r"^([^@]+)")
                .stringMatch(user.email.toString())
                .toString(),
            "email/" + user.uid: user.email,
            "fullname/" + user.uid: "",
            "gender/" + user.uid: "",
            "job/" + user.uid: "",
            "nik/" + user.uid: "",
            "phonenumber/" + user.uid: "",
            "zipcode/" + user.uid: "",
            "photoprofile/" + user.uid:
                "https://firebasestorage.googleapis.com/v0/b/myhealth-default-storage/o/blank_photo_profile.png?alt=media&token=b7c09a0d-cd6c-4514-9498-647b5df0bd28"
          });
          var accessEntry = AccessEntryBlockChain(user.uid);
          _externalDocumentsDirectory = await getExternalStorageDirectory();
          Directory('${_externalDocumentsDirectory!.path}/Akses Rekam Medis/')
              .createSync(recursive: true);

          File fileToHealthRecordAccess = File(
              "${_externalDocumentsDirectory.path}/Akses Rekam Medis/${user.uid}");

          fileToHealthRecordAccess
              .writeAsString(jsonEncode(accessEntry.toJson()));

          Reference healthRecordAccessref = FirebaseStorage.instance
              .ref()
              .child('health-record-access')
              .child(user.uid);

          try {
            await healthRecordAccessref
                .putData(await fileToHealthRecordAccess.readAsBytes());
          } catch (e) {
            print(e.toString());
            try {
              await healthRecordAccessref
                  .putFile(File(fileToHealthRecordAccess.path));
            } catch (e) {
              print(e.toString());
              return e.toString();
            }
          }
        } catch (e) {
          print(e.toString());
          return e.toString();
        }

        await logout();
      } catch (e) {
        print(e.toString());
        return e.toString();
      }
    } on FirebaseAuthException catch (e) {
      print(e.code);
      return e.code;
      // if (e.code == 'weak-password') {
      //   print(e.code);
      //   return e.code;
      // } else if (e.code == 'email-already-in-use') {
      //   print('The account already exists for that email.');
      //   Fluttertoast.showToast(msg: "Email sudah digunakan!");
      // }
    } catch (e) {
      print(e.toString());
      return "";
    }

    return "true";
  }

  Future<String> logout() async {
    String logoutcode = "true";
    try {
      googleSignIn.disconnect();
      FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e.toString());
      print("logout");
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        print(e.toString());
        print("logout");
        logoutcode = "false";
      }
    }

    return logoutcode;
  }
}
