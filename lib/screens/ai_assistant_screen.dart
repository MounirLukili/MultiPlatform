// lib/screens/ai_assistant_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // Pour l'effet de flou
import '../services/openai_service.dart';
import '../services/places_service.dart';
import '../providers/city_provider.dart';
import '../models/place_model.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _aiService = OpenAIService();
  final PlacesService _placesService = PlacesService();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'text': "Bonjour et bienvenue ! 🌍✨\n\n"
              "Je suis ton assistant personnel. J'ai faim, soif de culture ou besoin de nature ? Dis-le moi simplement (ex: 'Meilleur burger', 'Parc calme', 'Pharmacie ouverte').\n\n"
              "Je chercherai pour toi sur la carte ! 🗺️",
      'isUser': false,
    }
  ];
  
  bool _isTyping = false;
  bool _isSearching = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add({'text': userText, 'isUser': true});
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final Map<String, String> response = await _aiService.getChatResponse(userText);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': response['message'], 
          'isUser': false,
          'keyword': response['keyword'] 
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _launchSmartSearch(String keyword) async {
    setState(() => _isSearching = true);

    try {
      final city = Provider.of<CityProvider>(context, listen: false).currentCity;
      if (city == null) return;

      final Place? bestPlace = await _placesService.searchPlaceByText(
        keyword, 
        city.latitude, 
        city.longitude
      );

      if (mounted) {
        setState(() => _isSearching = false);
        if (bestPlace != null) {
          Navigator.pop(context, bestPlace);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rien trouvé pour '$keyword'."), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // --- UI WIDGETS ---

  Widget _buildMessageBubble(String text, bool isUser, String? keyword) {
    // ⚠️ LARGEUR DYNAMIQUE : 80% de l'écran au lieu de 300px fixe
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.80;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth), // ⚠️ ICI LA CORRECTION
        decoration: BoxDecoration(
          color: isUser ? Colors.amber : const Color(0xFF2A2A3A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ⚠️ IMPORTANT : Prend juste la place nécessaire
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.black87 : Colors.white.withOpacity(0.95),
                fontSize: 15,
                height: 1.4,
                fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            
            if (!isUser && keyword != null && keyword.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : () => _launchSmartSearch(keyword),
                    icon: _isSearching 
                        ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.map, size: 18),
                    label: Text(_isSearching ? "Recherche..." : "Voir sur la carte ($keyword)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.amber,
                      elevation: 0,
                      side: const BorderSide(color: Colors.amber, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 10),
            Text("Assistant IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(left: 20, top: 10),
                    child: Text("L'assistant réfléchit...", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                  );
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg['text'], msg['isUser'], msg['keyword']);
              },
            ),
          ),
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.9),
                  border: const Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Je veux...",
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Colors.black,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                        child: const Icon(Icons.send, color: Colors.black, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}