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

Le projet respecte une architecture propre (**Clean Architecture**) simplifiée, séparant clairement la logique métier, les données et l'interface utilisateur.

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
    * `WeatherCard`, `AnimatedPlaceCard`, `CategorySelector` : Widgets autonomes pour alléger les écrans principaux.

---

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


