import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spotired/src/data/models/access/access_key.dart';
import 'package:spotired/src/data/models/shared_preferences/enums/share_preference_values.enum.dart';
import 'package:spotired/src/data/services/data_service.dart';
import 'dart:math';

final accessController = AccessController();

class AccessController with ChangeNotifier {

  late AccessKey accessKey;
  ValueNotifier<bool> haveAccess = ValueNotifier<bool>(false);


  init() async {
    // GET SAVED ACCESS-KEY
    final jsonAccessKey = await dataService.get(SharePreferenceValues.accessKey);

    // GENERATE ACCESS-KEY
    if (jsonAccessKey == null) {
      final generatedKey = _generateKey(30);
      final generatedAccessKey = AccessKey(key: generatedKey, expirationDate: DateTime.now());
      await _saveAccessKey(generatedAccessKey);

      accessKey = generatedAccessKey;
    } else {
      final Map<String, dynamic> jsonMap = json.decode(jsonAccessKey);
      accessKey = AccessKey.fromJson(jsonMap);
    }

    // GIVE ACCESS
    await _giveAccess(accessKey, save: false);
  }

  void checkActualAccess() async {
    // GET ACCESS-KEYS
    final response = await http.get(Uri.parse('https://drive.google.com/uc?export=download&id=1FMQhYVqUaiy1giep0EPrDIPSQOk1rBY8'));
    if (response.statusCode != 200) return;

    // RESPONSE TO OBJ
    final List<dynamic> responseList = json.decode(response.body);
    List<AccessKey> accessKeys = responseList.map((item) => AccessKey.fromJson(item)).toList();

    // CHECK KEYS
    for (final accessKey in accessKeys) {
      if (accessKey.key == this.accessKey.key) {
        await _giveAccess(accessKey, save: true);
      }
    }
  }

  String _generateKey(int leng) {
    const caracteres = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      leng,
      (_) => caracteres.codeUnitAt(random.nextInt(caracteres.length)),
    ));
  }

  Future<void> _saveAccessKey(AccessKey accessKey) async {
    final strGeneratedAccessKey = json.encode(accessKey.toJson());
    await dataService.set(SharePreferenceValues.accessKey, strGeneratedAccessKey);
  }

  _giveAccess(AccessKey accessKey, {required bool save}) async {
    if (accessKey.expirationDate == null) {
      haveAccess.value = true;
    } else if (DateTime.now().isBefore(accessKey.expirationDate!)) {
      haveAccess.value = true;
    }

    if (save) await _saveAccessKey(accessKey);
  }
}