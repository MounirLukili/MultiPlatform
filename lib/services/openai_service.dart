// lib/services/openai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _apiKey = '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'; // Remettez votre clé
  
  // ⚠️ MODIFICATION : On prend une liste de messages (l'historique)
Future<Map<String, String>> getChatResponse(String userMessage) async {
    const String url = 'https://api.openai.com/v1/chat/completions';

    const String systemPrompt = 
        "Tu es un assistant qui traduit les envies des utilisateurs en recherche Google Maps. "
        "Ta réponse doit être UNIQUEMENT un objet JSON valide avec deux champs : "
        "1. 'reply': Une réponse courte, empathique et fun à l'utilisateur (en français). "
        "2. 'keyword': Le meilleur terme de recherche simple pour trouver ça sur Google Maps (ex: 'pizza', 'museum', 'park', 'pharmacy'). "
        "Exemple Utilisateur: 'J'ai mal à la tête' -> "
        "Réponse: {\"reply\": \"Aie, courage ! Voici les pharmacies les plus proches.\", \"keyword\": \"pharmacy\"}";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        
        // Parsing du JSON renvoyé par l'IA
        try {
          final Map<String, dynamic> jsonContent = jsonDecode(content);
          return {
            'message': jsonContent['reply'].toString(),
            'keyword': jsonContent['keyword'].toString(),
          };
        } catch (e) {
          // Fallback si l'IA plante le format JSON
          return {
            'message': "Je n'ai pas bien compris, mais je vais chercher ça.",
            'keyword': userMessage
          };
        }
      } else if (response.statusCode == 429) {
        return {'message': "Trop de demandes (Quota).", 'keyword': ''};
      } else {
        return {'message': "Erreur IA.", 'keyword': ''};
      }
    } catch (e) {
      return {'message': "Erreur réseau.", 'keyword': ''};
    }
  }
}