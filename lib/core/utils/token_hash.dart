import 'dart:convert';

import 'package:crypto/crypto.dart';

String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();
