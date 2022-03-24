
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:karymobiledev/NotificationSetting.dart';
import 'package:karymobiledev/SourceData.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Utils.dart';


class KaryWebView extends StatefulWidget {
  final String? link;
  final String? marketUrl;
  const KaryWebView({
    Key? key,
    this.link,
    this.marketUrl
  }) : super(key: key);

  @override
  _KaryWebViewState createState() => _KaryWebViewState();
}

class _KaryWebViewState extends State<KaryWebView> {

  final GlobalKey webViewKey = GlobalKey();


  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  //웹뷰 현재 url
  String url = "";
  //웹뷰 로딩진행상황
  double progress = 0;

  String? id;
  String? password;
  //sharedPreferences Instance
  late SharedPreferences prefs;


  //웹뷰 컨트롤러 선언
  InAppWebViewController? webViewController;
  //웹뷰 옵션
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(

      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        verticalScrollBarEnabled: false,


      ),
      android: AndroidInAppWebViewOptions(
        useWideViewPort: false,
        loadWithOverviewMode: true,
        useHybridComposition: true,

        mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW

      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,

      ),

  );
  //웹뷰 pullToRefresh 컨트롤러
  late PullToRefreshController pullToRefreshController;
  //웹뷰 url 컨트롤러
  final urlController = TextEditingController();
  //웹뷰 뒤로가기
  Future<bool> _goBack(BuildContext context) async {
    if(webViewController==null){
      return true;
    }
    if(await webViewController!.canGoBack()){
      webViewController!.goBack();
      return Future.value(false);
    }else{
      Utils.FlutterDialog(context);
      return Future.value(true);
    }
  }
  //sharedPrefercences 얻기
  Future<void> _getSharedPreferencesInstance() async {
    prefs = await SharedPreferences.getInstance();
    _getLoginInfo();
  }
  //생체인증 authentication 선언
  LocalAuthentication authentication = LocalAuthentication();
  //생체인증 단말기가 생체인식 사용 가능한지 여부 선언 및 초기값할당
  bool _hasBiometric = false;
  //생체인증 생체인식 인증여부 선언 및 초기값할당
  bool _isAuthorized = false;
  //생체인증 단말기가 생체인식 사용가능한지 알아내는 메소드
  Future<void> _checkForBiometric() async {
    bool hasBiometric = false;
    try{
      hasBiometric = await authentication.canCheckBiometrics;
    } on PlatformException catch(e){
      print(e);
    }
    if(!mounted) return;
    setState(() {
      _hasBiometric = hasBiometric;
    });
  }
  //생체인증 인증받기
  Future<void> _getAuthentication() async {
    bool isAutherized = false;
    try{
      isAutherized = await authentication.authenticate(
        localizedReason: "지문로그인의 경우 지문센서에 손가락을 올려주세요. FaceID 로그인시 카메라를 응시해주세요",
        biometricOnly: true,
        useErrorDialogs: true,
        androidAuthStrings: AndroidAuthMessages(
          signInTitle: "캐리마켓 간편 로그인",
          cancelButton: "취소",
          biometricHint: ""
        ),
        iOSAuthStrings: IOSAuthMessages()

      );

    }on PlatformException catch(e){
      if(e.code=="NotEnrolled"){
        Get.snackbar('휴대폰에 저장된 생체정보가 없습니다', '고객님의 휴대폰 설정에서 생체정보를 등록해주세요',snackPosition: SnackPosition.BOTTOM,backgroundColor: Colors.grey.withOpacity(0.8));
      }
    }
    if(!mounted) return;
    setState(() {
      _isAuthorized = isAutherized;
    });
    if(_isAuthorized){
      _callSimpleLogin();
    }
  }
  //브릿지 함수 - SharedPreferences 에 로그인정보 저장( Id , Password )
  Future<void> _setLoginInfo(String id , String password) async {

    await prefs.setString('id', id);
    await prefs.setString('password', password);

    setState(() {
      _getLoginInfo();
    });
  }
  //브릿지 함수 - 생체인증 성공시 웹쪽에 로그인 요청
  void _callSimpleLogin() async{
    if(webViewController!=null){
      webViewController!.evaluateJavascript(source: 'simpleLoginFromApp("$id","$password")');
    }
  }
  //앱에 저장되있는 로그인용 고객 id,password 불러옴
  Future<void> _getLoginInfo() async{
    setState(() {
      id = prefs.getString('id');
      password = prefs.getString('password');
    });
  }
  //앱에 저장되있는 로그인용 고객 id,password 삭제
  Future<String> _deleteInfo()async{
      await prefs.remove('id');
      await prefs.remove('password');
      setState(() {
        id = null;
        password = null;
      });
      return 'Delete';
  }

  @override
  void initState() {
    super.initState();
    //웹뷰 pullToRefresh 컨트롤러 초기화
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
    //SharedPreferences Instance 획득
    _getSharedPreferencesInstance();
    //생체인증 단말기가 생체인증 가능한지 여부 메소드 호출
    _checkForBiometric();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop:()=> _goBack(context) ,
      child: Scaffold(
          body: SafeArea(
              child: Stack(

                children: [
                  InAppWebView(

                    key: webViewKey,
                    initialUrlRequest:
                    URLRequest(
                      url: Uri.parse(widget.link??widget.marketUrl??SourceData.marketUrl),

                    ),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                      webViewController?.addJavaScriptHandler(handlerName: 'saveInfo', callback: (args)async {
                        String id = args[0];
                        String password = args[1];
                        if(id!=null&&id!=""&&password!=null&&password!=""){
                          await _setLoginInfo(id,password);
                          Get.snackbar('로그인성공', '단말기에 로그인정보 저장, 다음부터 생체정보 로그인 사용가능',snackPosition: SnackPosition.BOTTOM,backgroundColor: Colors.grey.withOpacity(0.8));
                          return true;
                        }else{
                          Get.snackbar('로그인실패', '아이디 패스워드 정보가 없습니다.',snackPosition: SnackPosition.BOTTOM,backgroundColor: Colors.grey.withOpacity(0.8));
                          return false;
                        }
                      });
                      webViewController?.addJavaScriptHandler(handlerName: 'getFcmToken', callback: (args)async {
                        final token = await NotificationSetting().getToken();
                        return token;
                      });
                      webViewController?.addJavaScriptHandler(handlerName: 'getDeviceInfo', callback: (args)async {

                        if(Platform.isAndroid){
                          final info = await deviceInfo.androidInfo;
                          return '{"deviceModel":"${info.model}","deviceType":"APP_AOS"}';
                        }else if(Platform.isIOS){
                          final info = await deviceInfo.iosInfo;
                          return '{"deviceModel":"${info.name}","deviceType":"APP_IOS"}';
                        }else{
                          return '{"deviceModel":"ETC","deviceType":"APP_ETC"}';
                        }
                      });
                      webViewController?.addJavaScriptHandler(handlerName: 'deleteInfo', callback: (args)async {
                        await _deleteInfo();
                        if(id==null&&password==null){
                          return true;
                        }else{
                          return false;
                        }
                      });
                    },
                    androidOnFormResubmission:(controller, url) async{
                      return FormResubmissionAction.RESEND;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },

                    androidOnPermissionRequest: (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      var uri = navigationAction.request.url!;

                      if (![ "http", "https", "file", "chrome",
                        "data", "javascript", "about"].contains(uri.scheme)) {
                        if (await canLaunch(url)) {
                          // Launch the App
                          await launch(
                            url,
                          );
                          // and cancel the request
                          return NavigationActionPolicy.CANCEL;
                        }
                      }

                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                        urlController.text = this.url;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage);
                    },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                  (_hasBiometric==true&&id!=null&&password!=null&&url.contains("login"))
                  // (_hasBiometric==true)
                      ? Positioned(
                        bottom: 0,
                        height: 50,
                        width: Get.size.width,
                        child: Container(
                          color: Colors.red,
                          child: GestureDetector(
                            onTap: () async{
                              _getAuthentication();
                            },
                            child: Center(child: Text("간편 로그인"),),
                          ),
                        )
                        )
                      : SizedBox()
                ],
              ))),
    );
  }
}
