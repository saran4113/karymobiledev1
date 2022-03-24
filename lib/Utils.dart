import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Utils {
  static Future<String> downloadFile(String url, String fileName) async{

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    bool isValidUrl = await isUrlValid(url);
    if(isValidUrl){
      final response = await http.get(Uri.parse(url));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    }else{
      return '';
    }

  }

  //url이 유효하고, statusCode ==200 인 경우 true 리턴
  static Future<bool> isUrlValid(String url) async{

    //url 형태인지 확인
    bool isUrlType = Uri.parse(url).isAbsolute;
    if(isUrlType){
      try{
        final response = await http.get(Uri.parse(url));
        if(response.statusCode==200){
          return true;
        }else{
          return false;
        }
      }catch(e){
        return false;
      }
    }else{
      //url 형태가 아님
      return false;
    }

    return true;
  }

  //웹뷰 뒤로가기 더이상 없을때 경고창. 종료할지 여부
  static void FlutterDialog(context) {
    showDialog(
        context: context,
        //barrierDismissible - Dialog를 제외한 다른 화면 터치 x
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            //Dialog Main Title
            title: Column(
              children: <Widget>[
                new Text("캐리마켓 앱을 종료 하시겠습니까?"),
              ],
            ),
            //
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "다음에 또 만나요~",
                ),
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text("취소"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              new FlatButton(
                child: new Text("확인"),
                onPressed: () {
                  SystemNavigator.pop();
                },
              ),
            ],
          );
        });
  }


}