// lib/screens/dr_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // dataService 접근을 위해 main.dart 임포트
import 'package:health_app/models/chat_message.dart'; // 모델 임포트
import 'dart:convert'; // JSON 처리를 위해 추가
import 'package:http/http.dart' as http; // http 통신을 위해 추가

class DrChatScreen extends StatefulWidget {
  @override
  _DrChatScreenState createState() => _DrChatScreenState();
}

class _DrChatScreenState extends State<DrChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = []; // 채팅 메시지 목록
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러
  bool _isAiTyping = false; // AI가 응답을 준비 중인지 여부

  // FastAPI 서버 주소 (http -> https로 변경)
  final String _fastApiUrl = 'https://api.ssucheckmate.com/chat/dr.chat'; // 변경된 부분

  @override
  void initState() {
    super.initState();
    // 초기 AI 환영 메시지 추가
    _addMessage(ChatMessage(id: 'init_ai_message', text: '안녕하세요! 건강 관련해서 궁금한 점이 있으신가요? 증상을 말씀해주시면 예상되는 질병 정보를 찾아드릴게요.', isUserMessage: false, timestamp: DateTime.now()));
  }

  // 메시지를 목록에 추가하고 스크롤을 최하단으로 이동
  void _addMessage(ChatMessage message) {
    if (!mounted) return; // 위젯이 dispose되지 않았는지 확인
    setState(() {
      _messages.insert(0, message); // 새 메시지를 목록의 맨 앞에 추가 (역순으로 표시되므로)
    });
    // 스크롤을 최하단으로 이동 (새 메시지가 보이도록)
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  // 사용자 메시지 전송 및 AI 응답 처리
  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return; // 빈 메시지는 전송하지 않음
    _textController.clear(); // 입력 필드 초기화

    // 사용자 메시지 추가
    final userMessage = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, isUserMessage: true, timestamp: DateTime.now());
    _addMessage(userMessage);

    if (!mounted) return;
    setState(() {
      _isAiTyping = true; // AI 타이핑 상태 활성화
    });

    try {
      // FastAPI 서버로 요청 보내기
      final response = await http.post(
        Uri.parse(_fastApiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'query': text, // 사용자 입력 텍스트를 'query' 필드에 담아 전송
        }),
      );

      print('FastAPI 응답 상태 코드: ${response.statusCode}');
      print('FastAPI 응답 본문: ${utf8.decode(response.bodyBytes)}');

      String aiResponseText;
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        aiResponseText = responseData['response'] ?? '응답을 받을 수 없습니다.'; // 'response' 필드에서 AI 응답 추출
      } else {
        aiResponseText = '죄송합니다. AI 응답을 처리하는 데 문제가 발생했습니다. 상태 코드: ${response.statusCode}';
      }

      // AI 응답 메시지 추가
      final aiMessage = ChatMessage(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), text: aiResponseText, isUserMessage: false, timestamp: DateTime.now());
      _addMessage(aiMessage);

    } catch (e) {
      print('FastAPI 통신 오류: $e');
      final errorMessage = ChatMessage(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), text: '죄송합니다. 서버와 통신 중 오류가 발생했습니다: $e', isUserMessage: false, timestamp: DateTime.now());
      _addMessage(errorMessage);
    } finally {
      if (!mounted) return;
      setState(() {
        _isAiTyping = false; // AI 타이핑 상태 비활성화
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // 채팅 메시지 목록
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true, // 메시지를 역순으로 표시 (최신 메시지가 하단에 오도록)
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildChatMessageBubble(_messages[index]),
              ),
            ),
            // AI 타이핑 중일 때 로딩 인디케이터 표시
            if (_isAiTyping)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [CircularProgressIndicator(strokeWidth: 2.0), SizedBox(width: 8.0), Text("Dr.Chat이 응답을 준비 중입니다...")],
                ),
              ),
            Divider(height: 1.0),
            // 메시지 입력 필드와 전송 버튼
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _isAiTyping ? null : _handleSubmitted, // AI 타이핑 중에는 전송 비활성화
                      decoration: InputDecoration.collapsed(hintText: "증상을 입력해주세요..."),
                      enabled: !_isAiTyping, // AI 타이핑 중에는 입력 비활성화
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                    onPressed: _isAiTyping ? null : () => _handleSubmitted(_textController.text), // AI 타이핑 중에는 전송 비활성화
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 채팅 메시지 버블 위젯 빌더
  Widget _buildChatMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft, // 사용자 메시지는 오른쪽, AI 메시지는 왼쪽
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: message.isUserMessage ? Colors.teal[100] : Colors.grey[300], // 메시지 타입에 따른 배경색
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: message.isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start, // 메시지 타입에 따른 텍스트 정렬
          children: [
            Text(message.text, style: TextStyle(fontSize: 15.0, color: Theme.of(context).textTheme.bodyLarge?.color)),
            SizedBox(height: 4.0),
            Text('${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 10.0, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}