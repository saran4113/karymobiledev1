import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:karymobiledev/KaryWebView.dart';
import 'Utils.dart';

class LocalNotificationSetting {
  static final _notifications= FlutterLocalNotificationsPlugin();

  static Future _notificationDetails(imagePath,iconPath) async{
    final bigPicturePath = await Utils.downloadFile(imagePath,'bigPicture');
    final largeIconPath = await Utils.downloadFile(iconPath,'largeIcon');

    if(bigPicturePath=='' || largeIconPath==''){

      return NotificationDetails(
        android: AndroidNotificationDetails(
            'channel alarm',
            'entire Noti',
            channelDescription: '캐리마켓 알림채널',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@drawable/splash',
            styleInformation: BigTextStyleInformation('')
        ),
        iOS: IOSNotificationDetails(),
      );
    }else{

      return NotificationDetails(
        android: AndroidNotificationDetails(
            'channel alarm',
            'entire Noti',
            channelDescription: '캐리마켓 알림채널',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@drawable/splash',
            largeIcon: FilePathAndroidBitmap(largeIconPath),
            styleInformation: BigPictureStyleInformation(
                FilePathAndroidBitmap(bigPicturePath),
                largeIcon: FilePathAndroidBitmap(largeIconPath)
            ),

        ),
        iOS: IOSNotificationDetails(
          // attachments: [IOSNotificationAttachment(largeIconPath)],

        ),
      );
    }
  }


  static Future initNotification() async {

    final android = AndroidInitializationSettings('@drawable/background');
    final iOS=IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    final settings = InitializationSettings(android: android,iOS: iOS);
    await _notifications.initialize(
      settings,
      onSelectNotification: (link) async {
        bool isValidUrl = await Utils.isUrlValid(link!);
        if(isValidUrl){
          Get.offAll(KaryWebView(link: link));
        }else{
          Get.offAll(KaryWebView());
        }

      },
    );
  }

  static Future showNotification({
    int id =0,
    String?title,
    String?body,
    String?link,
    String?imagePath,
    String?iconPath,
  }) async =>
      _notifications.show(
        id,
        title,
        body,
        await _notificationDetails(imagePath,iconPath),
        payload: link,
      );

}