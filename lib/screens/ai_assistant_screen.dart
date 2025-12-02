// lib/screens/ai_assistant_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      'text': "Dis-moi ce que tu veux faire (ex: 'J'ai faim', 'Je veux courir', 'Soirée romantique')... Je m'occupe du reste !",
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

    // Appel à l'IA (Plus besoin de la ville ici, on veut juste l'intention)
    final Map<String, String> response = await _aiService.getChatResponse(userText);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': response['message'], // La phrase sympa
          'isUser': false,
          'keyword': response['keyword'] // Le mot clé technique (caché ou utilisé pour le bouton)
        });
      });
      _scrollToBottom();
    }
  }

  // Lancer la recherche Google avec le mot clé fourni par l'IA
  Future<void> _launchSmartSearch(String keyword) async {
    setState(() => _isSearching = true);

    try {
      final city = Provider.of<CityProvider>(context, listen: false).currentCity;
      if (city == null) return;

      // Recherche Google Places "Text Search" avec le mot clé magique
      // On cherche "keyword" autour de la position actuelle
      final Place? bestPlace = await _placesService.searchPlaceByText(
        keyword, 
        city.latitude, 
        city.longitude
      );

      if (mounted) {
        setState(() => _isSearching = false);
        if (bestPlace != null) {
          Navigator.pop(context, bestPlace); // On renvoie le lieu trouvé à la carte
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rien trouvé pour '$keyword' autour de vous.")),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Assistant Intelligent"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Column(
        children: [
          if (_isSearching) const LinearProgressIndicator(color: Colors.indigo),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'];
                final keyword = msg['keyword'] as String?;

                return Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Bulle Message
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.indigo : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        msg['text'],
                        style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16),
                      ),
                    ),

                    // BOUTON MAGIQUE (Si l'IA a trouvé un mot clé valide)
                    if (!isUser && keyword != null && keyword.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 5),
                        child: ElevatedButton.icon(
                          onPressed: _isSearching ? null : () => _launchSmartSearch(keyword),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: Text("Trouver : $keyword"), // Affiche le terme technique (ex: 'Bakery')
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          // ... (Zone de saisie inchangée - Gardez votre code précédent pour le TextField) ...
          // Juste pour être sûr, je remets le bloc du bas :
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Je veux...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  backgroundColor: Colors.indigo,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}