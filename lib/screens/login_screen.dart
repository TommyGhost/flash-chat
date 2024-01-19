// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/components/rounded_button.dart';
import 'package:flash_chat/constants.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class LoginScreen extends StatefulWidget {
  static const String id = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;
  String email = '';
  String password = '';
  final formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final emailReg =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Flexible(
                    child: Hero(
                      tag: 'logo',
                      child: SizedBox(
                        height: 200.0,
                        child: Image.asset('images/logo.png'),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 48.0,
                  ),
                  TextFormField(
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      email = value;
                    },
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Enter your email'),
                    autofillHints: const [AutofillHints.email],
                    validator: (val) {
                      String validate = val!.replaceAll(RegExp(r"\s+"), "");
                      if (validate.isEmpty ||
                          !RegExp(emailReg).hasMatch(validate)) {
                        return 'Enter valid email';
                      }
                      return null;
                    },
                    autovalidateMode: _autovalidateMode,
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  TextFormField(
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      password = value;
                    },
                    obscureText: true,
                    decoration: kTextFieldDecoration,
                    validator: (val) {
                      if (val!.isEmpty) {
                        return "Please enter your password";
                      }
                      return null;
                    },
                    autovalidateMode: _autovalidateMode,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(
                    height: 24.0,
                  ),
                  RoundedButton(
                    title: 'Log In',
                    color: Colors.lightBlueAccent,
                    onPressed: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          showSpinner = true;
                        });
                        try {
                          final user = await _auth.signInWithEmailAndPassword(
                              email: email, password: password);
                          // ignore: unnecessary_null_comparison
                          if (user != null) {
                            Navigator.pushNamed(context, ChatScreen.id);
                          }

                          setState(() {
                            showSpinner = false;
                          });
                        } catch (e) {
                          print(e);
                          String errorMessage = 'An error occurred.';

                          if (e is FirebaseAuthException) {
                            // Handle FirebaseAuthException errors
                            errorMessage = e.message ?? errorMessage;
                          } else if (e is Exception) {
                            // Handle other types of exceptions
                            errorMessage = e.toString();
                          }
                          setState(() {
                            showSpinner = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              errorMessage,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.left,
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ));
                        }
                      } else {
                        setState(() {
                          _autovalidateMode =
                              AutovalidateMode.onUserInteraction;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
