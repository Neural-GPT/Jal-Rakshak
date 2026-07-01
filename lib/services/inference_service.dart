import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class InferenceResult {
  final String label;        // 'filling' | 'filled'
  final double confidence;   // probability of the winning class
  final double fillingProb;  // raw softmax P(filling)
  final double filledProb;   // raw softmax P(filled)
  final double rms;
  final List<double> embeddings;

  const InferenceResult({
    required this.label,
    required this.confidence,
    required this.fillingProb,
    required this.filledProb,
    required this.rms,
    required this.embeddings,
  });
}

class InferenceService {
  static const int yamnetFrameSamples = 15600;
  static const int sampleRate         = 16000;
  static const int windowSamples      = 80000;
  static const int embeddingDim       = 1024;

  Interpreter? _yamnet;
  Interpreter? _head;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> load() async {
    try {
      final options = InterpreterOptions()..threads = 2;

      _yamnet = await Interpreter.fromAsset(
        'assets/models/yamnet.tflite',
        options: options,
      );
      _head = await Interpreter.fromAsset(
        'assets/models/jal_rakshak_head.tflite',
        options: options,
      );

      final inShape  = _yamnet!.getInputTensor(0).shape;
      final outShape = _yamnet!.getOutputTensor(0).shape;
      debugPrint('[InferenceService] YAMNet input:  $inShape');
      debugPrint('[InferenceService] YAMNet output: $outShape');
      debugPrint('[InferenceService] Head input:    ${_head!.getInputTensor(0).shape}');
      debugPrint('[InferenceService] Head output:   ${_head!.getOutputTensor(0).shape}');

      if (outShape.last != embeddingDim) {
        throw Exception(
          'Wrong YAMNet model! Output=$outShape, expected last dim=$embeddingDim. '
          'Use yamnet_embeddings.tflite.',
        );
      }

      _ready = true;
      debugPrint('[InferenceService] ✓ Models loaded and validated.');
    } catch (e) {
      debugPrint('[InferenceService] Load error: $e');
      rethrow;
    }
  }

  /// [filledThreshold]: minimum filledProb to classify as FILLED.
  /// If filledProb < filledThreshold → label = 'filling' regardless of argmax.
  /// This means "filled" only fires when the model is genuinely confident.
  Future<InferenceResult?> infer(
    List<double> pcm, {
    double filledThreshold = 0.70,
  }) async {
    if (!_ready || _yamnet == null || _head == null) return null;
    if (pcm.length < yamnetFrameSamples) {
      debugPrint('[InferenceService] PCM too short: ${pcm.length}');
      return null;
    }

    // Normalize to [-1, 1]
    final wave = List<double>.from(pcm);
    double peak = 0;
    for (final s in wave) { if (s.abs() > peak) peak = s.abs(); }
    if (peak > 1e-6) {
      for (int i = 0; i < wave.length; i++) wave[i] /= peak;
    }

    final rms = _computeRms(wave);

    // Run YAMNet frame by frame: input [15600] → output [1, 1024]
    final accumulatedEmb = List<double>.filled(embeddingDim, 0.0);
    int validFrames = 0;
    int offset = 0;

    while (offset + yamnetFrameSamples <= wave.length) {
      final frame  = wave.sublist(offset, offset + yamnetFrameSamples);
      offset      += yamnetFrameSamples;

      final output = [List<double>.filled(embeddingDim, 0.0)];
      try {
        _yamnet!.run(frame, output);
      } catch (e) {
        debugPrint('[InferenceService] YAMNet frame error: $e');
        continue;
      }

      final emb = output[0];
      if (emb.length != embeddingDim) continue;
      for (int i = 0; i < embeddingDim; i++) {
        accumulatedEmb[i] += emb[i];
      }
      validFrames++;
    }

    if (validFrames == 0) {
      debugPrint('[InferenceService] No valid frames.');
      return null;
    }

    // Mean-pool
    final meanEmb = List<double>.filled(embeddingDim, 0.0);
    for (int i = 0; i < embeddingDim; i++) {
      meanEmb[i] = accumulatedEmb[i] / validFrames;
    }

    // MLP head: [1, 1024] → [1, 2]
    final headInput  = [meanEmb];
    final headOutput = [List<double>.filled(2, 0.0)];
    try {
      _head!.run(headInput, headOutput);
    } catch (e) {
      debugPrint('[InferenceService] Head error: $e');
      return null;
    }

    final fillingProb = headOutput[0][0];
    final filledProb  = headOutput[0][1];

    // ── Threshold-based classification ────────────────────────────────────
    // Only call it FILLED if filledProb exceeds the user-defined threshold.
    // Otherwise always call it FILLING — avoids false filled predictions.
    final isFilled  = filledProb >= filledThreshold;
    final label     = isFilled ? 'filled' : 'filling';
    final confidence = isFilled ? filledProb : fillingProb;

    debugPrint('[InferenceService] ─── RESULT ───────────────────────────');
    debugPrint('[InferenceService] fillingProb:  ${fillingProb.toStringAsFixed(4)}');
    debugPrint('[InferenceService] filledProb:   ${filledProb.toStringAsFixed(4)}');
    debugPrint('[InferenceService] threshold:    ${filledThreshold.toStringAsFixed(2)}');
    debugPrint('[InferenceService] Label:        ${label.toUpperCase()}');
    debugPrint('[InferenceService] Confidence:   ${(confidence * 100).toStringAsFixed(1)}%');
    debugPrint('[InferenceService] RMS:          ${rms.toStringAsFixed(4)}');
    debugPrint('[InferenceService] ──────────────────────────────────────');

    return InferenceResult(
      label:       label,
      confidence:  confidence,
      fillingProb: fillingProb,
      filledProb:  filledProb,
      rms:         rms,
      embeddings:  meanEmb,
    );
  }

  double _computeRms(List<double> samples) {
    double sum = 0;
    for (final s in samples) sum += s * s;
    return math.sqrt(sum / samples.length);
  }

  void dispose() {
    _yamnet?.close();
    _head?.close();
    _ready = false;
  }
}