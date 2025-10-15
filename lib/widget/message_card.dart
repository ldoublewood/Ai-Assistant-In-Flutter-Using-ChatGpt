import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../helper/global.dart';
import '../model/message.dart';

class MessageCard extends StatelessWidget {
  final Message message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(15);

    return message.msgType == MessageType.bot
        // AI机器人消息
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: mq.height * .02,
                    left: mq.width * .02,
                    right: mq.width * .1,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: mq.height * .015,
                    horizontal: mq.width * .03,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: r,
                      topRight: r,
                      bottomRight: r,
                    ),
                  ),
                  child: message.msg.isEmpty
                      ? AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              '正在思考中...',
                              speed: const Duration(milliseconds: 100),
                            ),
                          ],
                          repeatForever: true,
                        )
                      : MarkdownBody(
                          data: message.msg,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              height: 1.4,
                            ),
                            code: TextStyle(
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: Colors.blue,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          )
        // 用户消息
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: mq.height * .02,
                    right: mq.width * .02,
                    left: mq.width * .1,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: mq.height * .015,
                    horizontal: mq.width * .03,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      topLeft: r,
                      topRight: r,
                      bottomLeft: r,
                    ),
                  ),
                  child: Text(
                    message.msg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
            ],
          );
  }
}
