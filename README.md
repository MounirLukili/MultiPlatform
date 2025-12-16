# 🌍 Explorez Votre Ville

**Explorez Votre Ville** est une application mobile complète développée en Flutter (Dart). Elle agit comme un guide touristique intelligent et personnel, capable de s'adapter aux envies de l'utilisateur grâce à une intelligence artificielle, tout en fonctionnant partiellement hors ligne.

Ce projet met en œuvre des concepts avancés de développement mobile : architecture en couches, gestion d'état réactive, persistance de données locale et intégration de multiples API REST.

---

## 🚀 Fonctionnalités Détaillées

### 1. Cartographie & Géolocalisation Avancée
* **Moteur de Carte Open Source :** L'application utilise **OpenStreetMap** via le package `flutter_map`. Cela permet une indépendance totale vis-à-vis des coûts de Google Maps pour l'affichage cartographique.
* **Mode Sombre "Inversé" :** Une technique de filtrage matriciel (`ColorFilter.matrix`) est appliquée sur les tuiles de la carte pour simuler un mode sombre élégant sans nécessiter de serveurs de tuiles spécifiques payants.
* **Géocodage Inverse :** Conversion automatique des coordonnées GPS en nom de ville lisible via l'API Nominatim.

### 2. Assistant IA Contextuel
* **Traitement du Langage Naturel (NLP) :** Un chatbot intégré (alimenté par **OpenAI GPT-3.5**) analyse les demandes complexes de l'utilisateur (ex: *"Je veux un endroit romantique pour dîner"*).
* **Traduction d'Intention :** L'IA ne se contente pas de répondre ; elle extrait un **mot-clé de recherche** (ex: *restaurant*) qui est ensuite utilisé pour interroger l'API Google Places et afficher les résultats sur la carte.

### 3. Météo Dynamique
* **Données en Temps Réel :** Récupération de la température, humidité et vent via **OpenWeatherMap**.
* **Feedback Visuel :** L'interface s'adapte aux conditions météo grâce à des animations **Lottie** (soleil, pluie, nuages) pour une expérience utilisateur immersive.

### 4. Persistance & Mode Hors-Ligne
* **Base de Données Relationnelle (SQLite) :**
    * Stockage des lieux favoris et de l'historique des villes visitées.
    * Fonctionne sur mobile (`sqflite`) et sur le web (`sqflite_common_ffi_web`).
* **Notes Personnelles :** L'utilisateur peut ajouter ses propres commentaires et notes (étoiles) sur les lieux, qui sont sauvegardés localement.
* **Préférences Utilisateur :** Le thème (Clair/Sombre) et la dernière ville visitée sont persistés via `SharedPreferences`.

---

## 🛠️ Architecture Technique

Le projet respecte une architecture propre simplifiée, séparant clairement la logique métier, les données et l'interface utilisateur.

### 📂 Structure du Code

* **`lib/models/`** : Définit les structures de données (Objets Dart).
    * `City`, `Place`, `Weather` : Contiennent des méthodes `fromJson`/`toMap` pour faciliter la sérialisation avec les API et SQLite.
* **`lib/services/`** : Gère les appels réseaux et l'accès aux données.
    * `PlacesService` : Communique avec Google Places API.
    * `OpenAIService` : Gère le prompt système pour transformer le texte en JSON exploitable.
    * `DatabaseService` : Singleton gérant l'ouverture et les requêtes SQL sur la base locale.
* **`lib/providers/`** : Gestion d'état (State Management) avec le pattern **Provider**.
    * `CityProvider` : Centralise l'état de la ville actuelle et de la météo.
    * `PoiProvider` : Gère la liste des points d'intérêts affichés sur la carte.
    * `ThemeProvider` : Gère le basculement dynamique entre les thèmes clair et sombre.
* **`lib/widgets/`** : Composants UI réutilisables.
    * `WeatherCard`, `AnimatedPlaceCard`, `CategorySelector` : Widgets autonomes pour alléger les écrans principaux, refactor le code et le rendre plus laisible

---

## ⚠️ Disclaimer : L'IA est un poète, pas un GPS

Même en lui donnant gentiment votre position exacte, notre assistant IA souffre d'un **syndrome de l'envie d'ailleurs**.

Si vous lui demandez un bon restaurant à Orléans, il est tout à fait capable de vous recommander chaudement une adresse... **à New York ou Tokyo**. 🗽🇯🇵

* **Le problème :** L'IA privilégie la "popularité mondiale" à la "proximité locale". Pour elle, le meilleur burger du monde est à Manhattan, peu importe que vous soyez à 6000 km de là.
* **Notre solution :** Ne prenez pas ses suggestions de *noms* de lieux au pied de la lettre ! L'IA sert ici de **moteur d'inspiration** (trouver une idée : "Coréen", "Parc calme", "Musée insolite").
* **La réalité :** Une fois l'idée trouvée par l'IA, c'est notre application qui reprend la main pour chercher si ce type de lieu existe *vraiment* autour de vous via Google Maps.

*Bref, l'IA rêve, mais c'est la Carte qui conduit.* 🚗

### 
## ⚙️ Installation et Configuration

### Prérequis
* **Flutter SDK** (version stable récente).
* Récupérer le fichier .env présent dans le fichier zip et le mettre dans la racine du projet (meme niveau que pubspec.yaml)
* Accéder à ce lien https://cors-anywhere.herokuapp.com/corsdemo et clicker sur le bouton request pour permettre de tourner la version web du projet
* "flutter pub get" dans le terminal pour installer les dépendences.
* sudo apt update
  sudo apt install sqlite3 libsqlite3-0 libsqlite3-dev pour installer sqlite sur linux
* "flutter run" pour lancer sur un émulateur déjà configuré (de préférence sur chrome)
* "flutter build apk --release" pour générer le fichier apk (application installable)
* Commencer à découvrir les endroits qui vous intéressent :D








### Projet réalisé par Lukili Mounir et Bahhous Houssam-Eddine ###

### Quelques photos ###
<img width="859" height="895" alt="1" src="https://github.com/user-attachments/assets/0fd7955f-753b-4b57-81ab-999a36a99094" />
<img width="860" height="886" alt="2" src="https://github.com/user-attachments/assets/104cef2e-4c09-4b48-9a81-3023b1f904b1" />
<img width="860" height="886" alt="3" src="https://github.com/user-attachments/assets/2e5daab1-892d-4e3c-b165-ff6ae2e7d4d1" />
<img width="860" height="886" alt="4" src="https://github.com/user-attachments/assets/4f53c9af-7466-43dc-beff-23b8cccdff5d" />
<img width="860" height="886" alt="5" src="https://github.com/user-attachments/assets/1801d8b4-1f06-4802-9940-a18a8433c6c1" />
<img width="860" height="886" alt="6" src="https://github.com/user-attachments/assets/27ec6c0b-4e73-4c7c-a125-53004d4e6d3e" />
<img width="867" height="892" alt="7" src="https://github.com/user-attachments/assets/5e67dc59-094b-4420-9262-1ce92bacc01a" />
<img width="867" height="892" alt="8" src="https://github.com/user-attachments/assets/e0812805-d5be-429e-b8a8-5944bb9aa74d" />
<img width="867" height="892" alt="9" src="https://github.com/user-attachments/assets/2f50b59f-e27b-4ad0-a0f5-463a065ecd6f" />
<img width="867" height="892" alt="10" src="https://github.com/user-attachments/assets/7edd222a-4494-4644-b3d3-565e2d923543" />
<img width="867" height="892" alt="11" src="https://github.com/user-attachments/assets/e12891ac-ff7a-40d0-b92b-b0ece3bebedc" />
<img width="867" height="892" alt="12" src="https://github.com/user-attachments/assets/a6d3c3ac-1015-479d-b624-6dc31558423e" />

