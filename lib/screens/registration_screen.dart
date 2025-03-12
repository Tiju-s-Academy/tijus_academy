class _RegistrationScreenState extends State<RegistrationScreen> {import 'package:flutter/material.dart';



}  String? _phoneNumber;
class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();















































}  }    );      ),        ],          // ...existing code...          ),            },              _phoneNumber = value;            onSaved: (value) {            },              return null;              }                return 'Please enter a valid phone number';              if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {              }                return 'Please enter your phone number';              if (value == null || value.isEmpty) {            validator: (value) {            keyboardType: TextInputType.phone,            ),              ),                borderRadius: BorderRadius.circular(10),              border: OutlineInputBorder(              prefixIcon: Icon(Icons.phone),              hintText: 'Enter your phone number',              labelText: 'Phone Number',            decoration: InputDecoration(          TextFormField(          ),            // ...existing email validation code...            ),              // ...existing decoration code...              labelText: 'Email',            decoration: InputDecoration(          TextFormField(        children: <Widget>[      child: Column(      key: _formKey,    return Form(  Widget build(BuildContext context) {  @override  String _phoneNumber;  String _email;  final _formKey = GlobalKey<FormState>();}

class _RegistrationFormState extends State<RegistrationForm> {