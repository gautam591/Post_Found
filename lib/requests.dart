import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

bool refreshCSRF = true;
// const host = 'http://leonardo674.pythonanywhere.com';
const host = 'http://samirvadel31.pythonanywhere.com';
// const host = 'http://10.0.2.2:8000/';
const apiURLS = {
  'getCSRF'   : '$host/api/user/getcsrf/',
  'login'     : '$host/api/user/login/',
  'logout'    : '$host/api/user/logout/',
  'register'  : '$host/api/user/register/',
  'update'  : '$host/api/user/update/',
  'createPost'  : '$host/api/user/createPost/',
  'getPostEmergency'  : '$host/api/user/getPostEmergency/',
  'getPostRegular'  : '$host/api/user/getPostRegular/',
};

Future<dynamic> getLocalData(String key) async {
  final prefs = await SharedPreferences.getInstance();
  dynamic data = prefs.getString(key);
  if (data == null) {
    return '';
  }
  return data;
}

Future<bool> setLocalData(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  // Save data with a key
  data.forEach((key, value) {
    prefs.setString(key, value);
  });
  return true;
}

Future<void> deleteLocalData(String key) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.remove(key); // Delete a specific item, e.g., user token
}

Future<bool> deleteAllLocalData({String flag = 'soft'}) async {
  final prefs = await SharedPreferences.getInstance();
  if(flag == 'hard'){
    await prefs.clear();
  }
  else{
    String csrfValue = prefs.getString('CSRFToken') ?? '';
    await prefs.clear();
    await prefs.setString('CSRFToken', csrfValue);
  }
  return true;
}

class RequestHelper {
  static Future<String> getCSRFToken() async {
    String csrftoken = await getLocalData('CSRFToken') as String;
    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'csrftoken=$csrftoken',
      'Content-Length': '0',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    final response = await http.post(Uri.parse(apiURLS['getCSRF']!), headers: headers);
    if (response.statusCode == 200) {
      // final jsonResponse = json.decode(response.body);
      final cookies = response.headers['set-cookie']!;
      final cookieList = cookies.split('; ');
      // Iterate through the cookieList to find the 'csrftoken' cookie
      for (final cookie in cookieList) {
        // Split each cookie into name and value
        final parts = cookie.split('=');
        if (parts.length == 2) {
          final name = parts[0];
          final value = parts[1];
          if (name == 'csrftoken') {
            csrftoken = value; // Return the value of the 'csrftoken' cookie
          }
        }
      }
      setLocalData({'CSRFToken': csrftoken});
    }
    else {
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode}');
      }
    }
    if (kDebugMode) {
      print('CSRF Token => $csrftoken');
    }
    return csrftoken;
  }

  static Future<http.Response> sendGetRequest(String url, Map<String, String> headers) async {
    return http.get(Uri.parse(url), headers: headers);
  }

  static Future<http.Response> sendPostRequest(String url, Map<String, String> headers, Map<String, String> data) async {
    // String jsonBody = json.encode(data);
    return http.post(Uri.parse(url), headers: headers, body: data);
  }

// Add more request methods as needed (e.g., PUT, DELETE, etc.).
}

class API {
  API(){
    RequestHelper.getCSRFToken();
  }

  static Future<Map<String, dynamic>> login(Map<String, String> data) async{
    String csrf = await RequestHelper.getCSRFToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': 'csrftoken=$csrf;',
      'X-CSRFToken': csrf,
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    final response = await RequestHelper.sendPostRequest(apiURLS['login']!, headers, data);
    Map<String, dynamic> jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      if (jsonResponse["status"] == true) {
        setLocalData({'idToken': jsonResponse["data"]["idToken"]});
        setLocalData({'refreshToken': jsonResponse["data"]["refreshToken"]});
        setLocalData({'expiresIn': jsonResponse["data"]["expiresIn"]});
        setLocalData({'username': jsonResponse["data"]["username"]});
        setLocalData({'user': json.encode(jsonResponse["data"]["user"])});
        setLocalData({'user_details': json.encode(jsonResponse["data"]["user_details"])});
      }
      // print("Success: ${jsonResponse["messages"]["info"]}");
    } else {
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode} '
          '\nResponse Body:\n ${response.body}');
      }
    }
    return jsonResponse;
  }

  static Future<Map<String, dynamic>> logout() async{
    deleteAllLocalData();
    Map<String, dynamic> jsonResponse = {'status': true};
    return jsonResponse;
  }

  static Future<Map<String, dynamic>> register(Map<String, String> data) async{
    String csrf = await RequestHelper.getCSRFToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': 'csrftoken=$csrf;',
      'X-CSRFToken': csrf,
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    final response = await RequestHelper.sendPostRequest(apiURLS['register']!, headers, data);
    Map<String, dynamic> jsonResponse = json.decode(response.body);

    if (response.statusCode == 201) {
      if (jsonResponse["status"] == true) {
        if (kDebugMode) {
          print("User created Successfully: ${jsonResponse["messages"]["success"]}");
        }
      }
      // print("Success: ${jsonResponse["messages"]["info"]}");
    } else {
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode} '
            '\nResponse Body:\n ${response.body}');
      }
    }
    return jsonResponse;
  }

  static Future<Map<String, dynamic>> update(Map<String, String> data) async{
    String csrf = await RequestHelper.getCSRFToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': 'csrftoken=$csrf;',
      'X-CSRFToken': csrf,
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    final response = await RequestHelper.sendPostRequest(apiURLS['update']!, headers, data);
    Map<String, dynamic> jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      if (jsonResponse["status"] == true) {
        setLocalData({'user': json.encode(jsonResponse["data"]["user"])});
        setLocalData({'user_details': json.encode(jsonResponse["data"]["user_details"])});
        if (kDebugMode) {
          print("User created Successfully: ${jsonResponse["messages"]["success"]}");
        }
      }
      // print("Success: ${jsonResponse["messages"]["info"]}");
    } else {
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode} '
            '\nResponse Body:\n ${response.body}');
      }
    }
    return jsonResponse;
  }

  static Future<Map<String, dynamic>> createPost(Map<String, String> data) async{
    String csrf = await RequestHelper.getCSRFToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': 'csrftoken=$csrf;',
      'X-CSRFToken': csrf,
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    final response = await RequestHelper.sendPostRequest(apiURLS['createPost']!, headers, data);
    Map<String, dynamic> jsonResponse = json.decode(response.body);

    if (response.statusCode == 201) {
      if (jsonResponse["status"] == true) {
        if (kDebugMode) {
          print("New post created successfully.");
        }
      }
    } else {
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode} '
            '\nResponse Body:\n ${response.body}');
      }
    }
    return jsonResponse;
  }

  static Future<Map<String, dynamic>> getPostEmergency({bool refresh = false}) async{
    Map<String, dynamic> jsonResponse = { };
    if (refresh == false) {
      String itemsRaw = await getLocalData('postEmergency') as String;
      jsonResponse['data'] = json.decode(itemsRaw);
      jsonResponse["status"] = true;
      return jsonResponse;
    }
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    final response = await RequestHelper.sendGetRequest(apiURLS['getPostEmergency']!, headers);
    jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      if (jsonResponse["status"] == true) {
        deleteLocalData('postEmergency');
        setLocalData({'postEmergency': json.encode(jsonResponse["data"])});
      }
    } else {
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode} '
            '\nResponse Body:\n ${response.body}');

      }
    }
    return jsonResponse;
  }

  static Future<Map<String, dynamic>> getPostRegular({bool refresh = false}) async{
    Map<String, dynamic> jsonResponse = { };
    if (refresh == false) {
      String itemsRaw = await getLocalData('postRegular') as String;
      jsonResponse['data'] = json.decode(itemsRaw);
      jsonResponse["status"] = true;
      return jsonResponse;
    }
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    final response = await RequestHelper.sendGetRequest(apiURLS['getPostRegular']!, headers);
    jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      if (jsonResponse["status"] == true) {
        deleteLocalData('postRegular');
        setLocalData({'postRegular': json.encode(jsonResponse["data"])});
      }
    } else {
      if (kDebugMode) {
        print('Request failed with status: ${response.statusCode} '
            '\nResponse Body:\n ${response.body}');

      }
    }
    return jsonResponse;
  }

  static Future<void> getAllData() async{
    await API.getPostEmergency(refresh: true);
    await API.getPostRegular(refresh: true);
  }
}
