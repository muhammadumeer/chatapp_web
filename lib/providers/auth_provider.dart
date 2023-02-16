import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chatapp_web/constants/constants.dart';
import 'package:chatapp_web/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateException,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  // final GoogleSignIn googleSignIn;
  // final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  Status _status = Status.uninitialized;

  Status get status => _status;

  AuthProvider({
    // required this.firebaseAuth,
    // required this.googleSignIn,
    required this.prefs,
    required this.firebaseFirestore,
  });

  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggedIn() async {
    // bool isLoggedIn = await googleSignIn.isSignedIn();
    if (prefs.getString(FirestoreConstants.id)?.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();

    // GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    // if (googleUser != null) {
    //   GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
    //   final AuthCredential credential = GoogleAuthProvider.credential(
    //     accessToken: googleAuth.accessToken,
    //     idToken: googleAuth.idToken,
    //   );

      // User? firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

      String? uid = await _getId();
      // if (firebaseUser != null) {
      if (uid != null) {
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: uid)
            .get();
        final List<DocumentSnapshot> documents = result.docs;
        if (documents.length == 0) {
          // Writing data to server because here is a new user
          firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(uid).set({
            FirestoreConstants.nickname: uid.substring(3,7),
            FirestoreConstants.photoUrl: "",
            FirestoreConstants.id: uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null
          });

          // Write data to local storage
          // User? currentUser = firebaseUser;
          await prefs.setString(FirestoreConstants.id, uid);
          await prefs.setString(FirestoreConstants.nickname, uid.substring(3,7) ?? "");
          await prefs.setString(FirestoreConstants.photoUrl, "" ?? "");
        } else {
          // Already sign up, just get data from firestore
          DocumentSnapshot documentSnapshot = documents[0];
          UserChat userChat = UserChat.fromDocument(documentSnapshot);
          // Write data to local
          await prefs.setString(FirestoreConstants.id, userChat.id);
          await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
          await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
          await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
        }
        _status = Status.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    // }
    // else {
    //   _status = Status.authenticateCanceled;
    //   notifyListeners();
    //   return false;
    // }
  }

  Future<String?> _getId()async {
    String? id = "assassdeqwert32";
    id = await prefs.getString(FirestoreConstants.id);
    if(id != null){
      return id;
    }

    bool unique = false;
    while (unique == false) {
      id = getRandomString(15);
      final QuerySnapshot result = await firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.id, isEqualTo: id)
          .get();
      if(result.size == 0){
        unique = true;
      }
    }
    return id;
  }


  var _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  void handleException() {
    _status = Status.authenticateException;
    notifyListeners();
  }

  Future<void> handleSignOut() async {
    await prefs.setString(FirestoreConstants.id,"");
    _status = Status.uninitialized;
    // await firebaseAuth.signOut();
    // await googleSignIn.disconnect();
    // await googleSignIn.signOut();
  }
}
