import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care/AIScreen/colorsSchemeGPT.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/DataBase.dart';
import 'package:pet_care/AIScreen/TypingIndicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_keys.dart';

class gptScreenDark extends StatefulWidget {
  const gptScreenDark({super.key});

  @override
  State<gptScreenDark> createState() => _GptScreenState();
}

class _GptScreenState extends State<gptScreenDark> {
  List<Map<dynamic, dynamic>> messageList = [
    {
      "IsUser": false,
      "message": "Hi. I am your AI Doctor.\nHow can I assist you?",
    }
  ];

  TextEditingController messageController = TextEditingController();
  bool isLoading = false, isImageSelected = false,isSend=true;
  late File selectedImage;

  @override
  void initState() {
    super.initState();
    getSaveMessages();
  }

  showAlertBox() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pick Image From"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
                leading: Icon(Icons.camera_alt),
                title: Text("Camera"),
              ),
              ListTile(
                onTap: () {
                  pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
                leading: Icon(Icons.image),
                title: Text("Gallery"),
              ),
            ],
          ),
        );
      },
    );
  }

  pickImage(ImageSource imageSource) async {
    try {
      final photo = await ImagePicker().pickImage(source: imageSource);
      if (photo == null) {
        return;
      }
      final tempImage = File(photo.path);
      setState(() {
        selectedImage = tempImage;
        isImageSelected = true;
        messageList.add({
          "IsUser": true,
          "message": "",
          "image": selectedImage.path,
        });
      });
    } catch (ex) {
      setState(() {
        selectedImage = File("");
        isImageSelected = false;
      });
      print("Error ${ex.toString()}");
    }
  }

  geminiModelProVision(message) async {
    String apiResponse = message;

    final gemini = GoogleGemini(
      apiKey: GEMINIAPI,
    );

    await gemini
        .generateFromTextAndImages(query: message, image: selectedImage)
        .then((value) {
      apiResponse = value.text;
    }).catchError((e) => print(e));

    setState(() {
      isImageSelected = false;
      selectedImage = File("");
    });
    return apiResponse;
  }

  geminiModelPro(message) async {
    // var sh=await SharedPreferences.getInstance();
    // sh.remove("messageList");
    final safetySettings = [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
    ];
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: GEMINIAPI,
      safetySettings: safetySettings,
      systemInstruction: Content.system('You are an AI Pet Doctor. Your Name is Pettify. Only Answer Questions or Queries Related to Pets,Pet Care or related to Pets only or informations about Pets and their Foods ,details of animals or information is acceptable .Any query related to pet or animals is correct and you can answer it. Avoid any other questions.if user ask any unrelevant question simple refuse in a respected way."'),
    );
    final content = [Content.text(messageList.toString())];
    final response = await model.generateContent(content);
    return response.text;
  }

  getResponse(String text) async {
    setState(() {
      isLoading = true;
      messageList.add({"IsUser": false, "message": "Loading..."});
    });

    String response = "";
    if (isImageSelected) {
      response = await geminiModelProVision(text);
    } else {
      response = await geminiModelPro(text);
    }

    setState(() {
      isLoading = false;
      messageList.removeLast(); // Remove the loading message
      messageList.add({"IsUser": false, "message": response});
      isSend=true;
      saveMessages(messageList);
    });
  }

  getSaveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('messageList')) {
      String jsonString = prefs.getString('messageList') ?? '[]';
      List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        messageList =
            jsonList.map((item) => item as Map<dynamic, dynamic>).toList();
      });
    }
  }

  saveMessages(List<Map<dynamic, dynamic>> messages) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(messages);
    await prefs.setString('messageList', jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColorgpt,
            title: Text("AI Doctor",style: TextStyle(
              color: TextColor,
                fontSize:headingSize
            ),),
          ),
          body : Container(
            decoration: BoxDecoration(
              gradient: backgroundColor
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    height: double.maxFinite,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      gradient: backgroundColor
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.08,
                      ),
                      child: ListView.builder(
                        itemCount: messageList.length,
                        itemBuilder: (context, index) {
                          var message = messageList[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: message['IsUser']
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  gradient: message['IsUser']
                                      ? BackgroundOverlayColor
                                      : chatReplyColor,
                                  borderRadius: message['IsUser']
                                      ? BorderRadius.only(
                                      topRight: Radius.circular(15),
                                      topLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15))
                                      : BorderRadius.only(
                                      topRight: Radius.circular(15),
                                      topLeft: Radius.circular(15),
                                      bottomLeft: Radius.circular(15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message['message'] == "Loading...")
                                      TypingIndicator()
                                    else
                                      Text(
                                        message['message'],
                                        style: TextStyle(
                                          color: message['IsUser']
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                      ),
                                    if (message.containsKey('image'))
                                      SizedBox(
                                        height: 200,
                                        width: 200,
                                        child: Image.file(
                                          File(message['image']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 7,
                  left: MediaQuery.of(context).size.width * 0.02,
                  right: MediaQuery.of(context).size.width * 0.02,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff2A2438),
                          blurRadius: 12,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: TextField(
                        enabled: isSend,
                        maxLines: null,
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xff79777D),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          suffixIcon: IconButton(
                            onPressed: () {
                              showAlertBox();
                            },
                            icon: Icon(Icons.add),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          if (messageController.text.isNotEmpty) {
                            setState(() {
                              messageList.add({
                                "IsUser": true,
                                "message": messageController.text,
                              });
                              isSend=false;
                              getResponse(messageController.text);
                              messageController.clear();
                            });
                          }
                        },
                        icon: Icon(
                          Icons.send,
                          color:Color.fromRGBO(92, 84, 112, 1),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
      );
  }
}
