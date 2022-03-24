import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:karymobiledev/NotificationSetting.dart';
import 'KaryWebView.dart';
import 'SourceData.dart';
import 'Utils.dart';


Future main() async {

  String? initUrl;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  DocumentSnapshot data = await fireStore.collection('link').doc('address').get();
  String marketUrl;
  NotificationSetting().setNotifications();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    sound: false,
  );
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessaged);
  try{
    marketUrl = data['url'];
    bool isValidUrl = await Utils.isUrlValid(marketUrl);
    if(!isValidUrl){
      marketUrl = SourceData.marketUrl;
    }
  }catch(e){
    marketUrl = SourceData.marketUrl;

  };

  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if(null!=initialMessage){

    String? url = initialMessage.data['link'];
    if(url!=null){
      final isValidUrl = await Utils.isUrlValid(url);
      if(isValidUrl){
        initUrl=url;
      }else{
        initUrl=null;
      }
    }
  }

  if (Platform.isAndroid) {
    // await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

    NotificationSetting().subscribeTopic('AOS');
  }else if(Platform.isIOS){
    NotificationSetting().subscribeTopic('IOS');

  }

  runApp(new MyApp(link: initUrl,marketUrl: marketUrl));
}

Future<void> _onBackgroundMessaged(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class MyApp extends StatefulWidget {
  final String? link;
  final String? marketUrl;

  MyApp({this.link,this.marketUrl});

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {



  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

        home: KaryWebView(link: widget.link,marketUrl: widget.marketUrl),

    );
  }

}