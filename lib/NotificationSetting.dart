import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:karymobiledev/KaryWebView.dart';
import 'package:karymobiledev/LocalNotificationSetting.dart';

class NotificationSetting {

  setNotifications() async{

    //로컬 Notification init
    LocalNotificationSetting.initNotification();
    foregroundNotification();
    backgroundNotification();

  }

  subscribeTopic(topic){
    FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  getToken() async{
    final token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  //앱이 켜진 상태이고 현재 유저가 앱을 보고있을때
  foregroundNotification(){
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationSetting.showNotification(
          title: message.data['title']??'제목' ,
          body: message.data['body']??'내용',
          link: message.data['link']??"http://km-dev.thekary.com/",
          imagePath: message.data['imagePath']??"",
          iconPath: message.data['iconPath']??"",
      );
    });
  }

  //앱실행은 되어있는데 백그라운드 상태일때 푸시를 눌렀을때
  backgroundNotification(){
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Get.offAll(KaryWebView(link: message.data['link']??null));
    });
  }


}