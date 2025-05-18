/// TaxasGE – ModelService
/// -----------------------------------------------------------
/// Service singleton chargé de la gestion du modèle TensorFlow Lite
/// embarqué (assets/ml/taxasge_model.tflite).
/// -----------------------------------------------------------

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

/// Chemin et paramètres principaux
const String _kModelAssetPath = 'assets/ml/taxasge_model.tflite';
const int _kMaxSequenceLength =
    50; // séquence entrée fixée lors de l'entraînement

/*───────────────────────────────────────────────────────────────
  File d'attente interne : assure qu'une seule inférence est
  exécutée à la fois – l'interpréteur TFLite n'est pas thread‑safe.
───────────────────────────────────────────────────────────────*/
class _JobQueue {
  final _queue = Queue<Completer<void>>();

  Future<T> run<T>(Future<T> Function() task) async {
    // Chaque tâche ajoute son « ticket » dans la file
    final completer = Completer<void>();
    _queue.add(completer);

    // Si ce n'est pas son tour, elle attend la complétion du ticket en tête
    if (_queue.first != completer) await _queue.first!.future;
    try {
      return await task(); // Exécution protégée
    } finally {
      // Retrait du ticket et libération du suivant
      _queue.removeFirst();
      if (_queue.isNotEmpty) _queue.first!.complete();
    }
  }
}

/*───────────────────────────────────────────────────────────────
                       ModelService
───────────────────────────────────────────────────────────────*/
class ModelService {
  ModelService._internal();
  static final ModelService instance = ModelService._internal(); // singleton

  late final tfl.Interpreter _interpreter;
  bool _isInitialized = false;
  final _queue = _JobQueue();

  /*--------------------------- init ---------------------------*/
  Future<void> init() async {
    if (_isInitialized) return; // appel idempotent

    // Options de l'interpréteur (2 threads CPU par défaut)
    final options = tfl.InterpreterOptions()..threads = 2;

    // Delegate GPU si disponible → boost x3–5 sur la plupart des appareils
    try {
      options.addDelegate(tfl.GpuDelegateV2());
    } catch (_) {
      // Silencieux : certains appareils n'ont pas de support GPU
    }

    // Chargement depuis les assets
    _interpreter = await tfl.Interpreter.fromAsset(
      _kModelAssetPath,
      options: options,
    );

    _interpreter.allocateTensors(); // allocation mémoire (poids + IO)
    _isInitialized = true;
    if (kDebugMode) debugPrint('[ModelService] Modèle chargé');
  }

  /*------------------------- predict --------------------------*/
  Future<List<double>> predict(List<int> inputIds) async {
    if (!_isInitialized) {
      throw StateError('ModelService not initialized. Call init() first.');
    }

    // Padding/cut de la séquence à la taille attendue par le modèle
    final padded = List<int>.filled(_kMaxSequenceLength, 0);
    for (var i = 0; i < math.min(inputIds.length, _kMaxSequenceLength); ++i) {
      padded[i] = inputIds[i];
    }

    // TFLite accepte un batch de forme [1, seq_len] pour les IDs
    final input = [padded];

    // Pré-allocation du buffer de sortie (Float32List plat)
    final outputShape =
        _interpreter.getOutputTensor(0).shape; // e.g. [1, seq_len, vocab]
    final outputLen = outputShape.reduce((a, b) => a * b);
    final output = Float32List(outputLen);

    // Passage dans la file d'attente : exécution exclusive
    await _queue.run(() async {
      _interpreter.run(input, output);
    });

    return output.toList(growable: false); // conversion immuable
  }

  /*------------------------- dispose --------------------------*/
  void dispose() {
    if (_isInitialized) {
      _interpreter.close(); // libération du delegate + buffers
      _isInitialized = false;
    }
  }
}
