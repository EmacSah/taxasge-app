import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../services/localization_service.dart';
import '../database/database_service.dart';
import 'package:flutter/foundation.dart';

/// Service qui gère le modèle TensorFlow Lite du chatbot TaxasGE.
///
/// Cette classe est responsable du chargement et de l'initialisation des modèles
/// d'encodeur et de décodeur au format TFLite, ainsi que de la gestion des tokenizers.
class ModelService {
  // Singleton
  static final ModelService _instance = ModelService._internal();
  static ModelService get instance => _instance;

  // Base de données
  // ignore: unused_field
  final DatabaseService _dbService = DatabaseService();

  // Service de localisation
  // ignore: unused_field
  final LocalizationService _localizationService = LocalizationService.instance;

  // Interprètes TFLite
  Interpreter? _encoderInterpreter;
  Interpreter? _decoderInterpreter;

  // Tokenizers
  Map<String, dynamic>? _questionTokenizer;
  Map<String, dynamic>? _answerTokenizer;

  // Configuration
  static const int maxSequenceLength = 50;
  static const int vocabSize = 10000;

  // Flag d'initialisation
  bool _isInitialized = false;

  // Constructeur privé
  ModelService._internal();

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;



  /// Initialise le service en chargeant les modèles et tokenizers
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Charger les tokenizers JSON
      await _loadTokenizers();

      // Charger le modèle combiné
      final modelBytes = await _loadModel();
      final modelSizes = _extractModelSizes(modelBytes);
      final encoderBytes = modelBytes.sublist(16, 16 + modelSizes[0]);
      final decoderBytes = modelBytes.sublist(16 + modelSizes[0]);

      // Créer les interprètes
      _encoderInterpreter = Interpreter.fromBuffer(encoderBytes);
      _decoderInterpreter = Interpreter.fromBuffer(decoderBytes);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du modèle: $e');
      rethrow;
    }
  }

  /// Charge le modèle TFLite depuis les assets
  Future<Uint8List> _loadModel() async {
    try {
      return await rootBundle
          .load('assets/ml/taxasge_model.tflite')
          .then((byteData) => byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Erreur lors du chargement du modèle: $e');
      rethrow;
    }
  }

  /// Extrait les tailles des modèles d'encodeur et décodeur
  List<int> _extractModelSizes(Uint8List modelBytes) {
    final ByteData data = ByteData.view(modelBytes.buffer, 0, 16);
    return [
      data.getInt64(0, Endian.little), // Taille de l'encodeur
      data.getInt64(8, Endian.little), // Taille du décodeur
    ];
  }

  /// Charge les tokenizers depuis les fichiers JSON
  Future<void> _loadTokenizers() async {
    try {
      final questionTokenizerStr = await rootBundle
          .loadString('assets/ml/taxasge_model_question_tokenizer.json');
      final answerTokenizerStr = await rootBundle
          .loadString('assets/ml/taxasge_model_answer_tokenizer.json');

      _questionTokenizer = jsonDecode(questionTokenizerStr);
      _answerTokenizer = jsonDecode(answerTokenizerStr);
    } catch (e) {
      debugPrint('Erreur lors du chargement des tokenizers: $e');
      rethrow;
    }
  }

  /// Encode une séquence de texte avec le tokenizer approprié
  List<int> encodeText(String text, bool isQuestion) {
    final tokenizer = isQuestion ? _questionTokenizer : _answerTokenizer;
    if (tokenizer == null) {
      throw Exception('Tokenizer non initialisé');
    }

    // Utiliser le vocabulaire et l'index du tokenizer
    //final vocab = tokenizer['vocab'] as Map<String, dynamic>;
    final vocab = tokenizer['config']['word_index'] as Map<String, dynamic>;
    final words = text.toLowerCase().split(' ');
    final encoded = words.map((word) => vocab[word] ?? vocab['<OOV>']).toList();

    // Padding à la longueur maximale
    final padded = List<int>.filled(maxSequenceLength, 0);
    for (var i = 0; i < encoded.length && i < maxSequenceLength; i++) {
      padded[i] = encoded[i];
    }

    return padded;
  }

  /// Décode une séquence d'indices en texte
  String decodeSequence(List<int> sequence) {
    if (_answerTokenizer == null) {
      throw Exception('Tokenizer non initialisé');
    }

    // Récupérer le vocabulaire inversé
    //final indexToWord = Map<int, String>.fromEntries(
    //    (_answerTokenizer!['vocab'] as Map<String, dynamic>)
    //        .entries
    //        .map((e) => MapEntry(e.value as int, e.key)));

    final indexToWord = Map<int, String>.fromEntries(
        (_answerTokenizer!['config']['word_index'] as Map<String, dynamic>)
            .entries
            .map((e) => MapEntry(e.value as int, e.key)));

    // Filtrer les tokens spéciaux et de padding
    return sequence
        .where((index) => index > 0 && index < vocabSize)
        .map((index) => indexToWord[index] ?? '')
        .where((word) => word.isNotEmpty && !word.startsWith('<'))
        .join(' ');
  }

  /// Encode une question avec le modèle d'encodeur
  Future<List<double>> encodeQuestion(String question) async {
    if (!_isInitialized) await initialize();

    // Encoder le texte
    final input = encodeText(question, true);

    // Préparer les tenseurs d'entrée/sortie
    final inputTensor = [input];
    final outputTensor = List<List<double>>.filled(
        1, List<double>.filled(256, 0.0) // Taille des états cachés
        );

    // Exécuter l'encodeur
    _encoderInterpreter!.run(inputTensor, outputTensor);
    return outputTensor[0];
  }

  /// Génère une réponse avec le modèle de décodeur
  Future<String> generateResponse(List<double> encoderState) async {
    if (!_isInitialized) await initialize();

    // Initialiser la séquence de réponse avec un token de début
    List<int> outputSequence = [1]; // Token <START>

    // Token de fin
    const int endToken = 2; // Token <END>

    // État courant du décodeur
    var currentState = encoderState;

    // Générer la réponse token par token
    while (outputSequence.length < maxSequenceLength) {
      // Préparer les tenseurs d'entrée/sortie
      final inputTensor = [outputSequence.last];
      final stateTensor = [currentState];
      final outputTensor =
          List<List<double>>.filled(1, List<double>.filled(vocabSize, 0.0));
      final newStateTensor = List<List<double>>.filled(
          1, List<double>.filled(256, 0.0) // Taille des états cachés
          );

      // Exécuter le décodeur
      _decoderInterpreter!
          .run([inputTensor, stateTensor], [outputTensor, newStateTensor]);

      // Obtenir le token prédit
      final predictedToken = outputTensor[0]
          .asMap()
          .entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Mettre à jour l'état et la séquence
      currentState = newStateTensor[0];
      outputSequence.add(predictedToken);

      // Arrêter si on atteint le token de fin
      if (predictedToken == endToken) break;
    }

    // Décoder la séquence en texte
    return decodeSequence(outputSequence);
  }

  /// Ferme les ressources du modèle
  Future<void> dispose() async {
    _encoderInterpreter?.close();
    _decoderInterpreter?.close();
    _isInitialized = false;
  }
}
