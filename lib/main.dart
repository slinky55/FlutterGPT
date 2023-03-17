import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  try {
    await dotenv.load(fileName: "./.env");
  } catch (e) {
    print("$e");
  }

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: "FlutterGPT",
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.lightBlue,
        ),
        home: ChatPage(),
      )
    );
  }
}

class AppState extends ChangeNotifier {
  var messageLog = <MessageBubble>[];

  // ignore: non_constant_identifier_names
  static final OPENAI_SECRET = dotenv.env['OPENAI_SECRET'];

  void addMsg(MessageBubble msg) {
    messageLog.add(msg);
    notifyListeners();
  }
}

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var log = state.messageLog;

    return Scaffold(
      appBar: AppBar(
        title: const Text("FlutterGPT"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: log.length,
              itemBuilder: (context, index) {
                return log[index];
              },
            ),
          ),
          MessageBar(),
        ], // children
      ),
    );
  }
}

class MessageBar extends StatelessWidget {
  final _textController = TextEditingController();

  Future<String> sendMessage(String message) async {
    try {
      var res = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          HttpHeaders.contentTypeHeader: "application/json",
          HttpHeaders.authorizationHeader: "Bearer ${dotenv.env['OPENAI_SECRET']}"
        },
        body: jsonEncode(<String, Object>{
          "model": "gpt-3.5-turbo",
          "messages": [{
            "role": "user",
            "content": message
          }],
          "temperature": 0.7
        }),
      );

      return jsonDecode(res.body)["choices"][0]["message"]["content"].toString().trim();
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    var state = context.read<AppState>();

    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Message",
              ),
              onSubmitted: (String value) async {
                if (value.isEmpty) return;
                String usr = value;
                state.addMsg(
                  MessageBubble(
                    usr,
                    true,
                  ),
                );
                _textController.text = "";

                String gpt = await sendMessage(usr);
                state.addMsg(
                  MessageBubble(
                    gpt,
                    false,
                  ),
                );
              }
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              if (_textController.text.isEmpty) return;
              String usr = _textController.text;
              state.addMsg(
                MessageBubble(
                  usr,
                  true,
                ),
              );
              _textController.text = "";

              String gpt = await sendMessage(usr);
              state.addMsg(
                MessageBubble(
                  gpt,
                  false,
                ),
              );
            },
            child: Text("Send"),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  MessageBubble(this.text, this.isUser);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      width: 200,
      decoration: BoxDecoration(
        color: isUser ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}