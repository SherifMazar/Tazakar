package com.tazakar.tazakar

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Native Android handler for the Tazakar AI platform channel.
 * Channel: com.tazakar.app/ai_channel
 *
 * Audio pipeline: AudioRecord → RNNoiseProcessor → Whisper-tiny INT8
 */
class AiChannelHandler(
  private val activity: FlutterActivity,
  flutterEngine: FlutterEngine,
) : MethodChannel.MethodCallHandler {

  companion object {
    const val CHANNEL_NAME = "com.tazakar.app/ai_channel"
    private const val SAMPLE_RATE = 16000
    private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
  }

  private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
  private val scope = CoroutineScope(Dispatchers.Main)

  private var audioRecord: AudioRecord? = null
  private var isRecording = false
  private var recordedBytes = mutableListOf<Byte>()
  private var isModelReady = false

  init {
    channel.setMethodCallHandler(this)
    RNNoiseProcessor.init()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "loadModel"       -> handleLoadModel(result)
      "isModelLoaded"   -> result.success(isModelReady)
      "startRecording"  -> handleStartRecording(result)
      "stopRecording"   -> handleStopRecording(result)
      "transcribeAudio" -> {
        val audioBytes = call.argument<ByteArray>("audioBytes")
        if (audioBytes == null) {
          result.error("INVALID_ARGS", "audioBytes is required", null)
        } else {
          handleTranscribeAudio(audioBytes, result)
        }
      }
      else -> result.notImplemented()
    }
  }

  // ─────────────────────────────────────────────
  // MODEL MANAGEMENT
  // ─────────────────────────────────────────────

  private fun handleLoadModel(result: MethodChannel.Result) {
    // TODO(S3.3-Obj5): Load whisper-tiny-int8.tflite from assets
    isModelReady = true
    android.util.Log.d("AiChannel", "loadModel → stub ready")
    result.success(true)
  }

  // ─────────────────────────────────────────────
  // AUDIO RECORDING
  // ─────────────────────────────────────────────

  private fun handleStartRecording(result: MethodChannel.Result) {
    if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO)
      != PackageManager.PERMISSION_GRANTED
    ) {
      result.error("PERMISSION_DENIED", "Microphone permission not granted", null)
      return
    }

    if (isRecording) {
      result.error("ALREADY_RECORDING", "Recording already in progress", null)
      return
    }

    scope.launch {
      try {
        val minBufferSize = AudioRecord.getMinBufferSize(
          SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT
        )

        audioRecord = AudioRecord(
          MediaRecorder.AudioSource.MIC,
          SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, minBufferSize
        )

        recordedBytes.clear()
        isRecording = true
        audioRecord?.startRecording()

        android.util.Log.d("AiChannel", "startRecording → 16kHz mono PCM")
        result.success(true)

        withContext(Dispatchers.IO) {
          val buffer = ByteArray(minBufferSize)
          while (isRecording) {
            val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
            if (read > 0) recordedBytes.addAll(buffer.take(read))
          }
        }
      } catch (e: Exception) {
        android.util.Log.e("AiChannel", "startRecording error: ${e.message}")
        result.error("RECORDING_ERROR", e.message, null)
      }
    }
  }

  private fun handleStopRecording(result: MethodChannel.Result) {
    if (!isRecording) {
      result.error("NOT_RECORDING", "No active recording to stop", null)
      return
    }

    isRecording = false
    audioRecord?.stop()
    audioRecord?.release()
    audioRecord = null

    val rawBytes = recordedBytes.toByteArray()

    // ── RNNoise pipeline (stub in Phase 3.3, real processing in Phase 4) ──
    val denoisedBytes = RNNoiseProcessor.process(rawBytes)

    android.util.Log.d(
      "AiChannel",
      "stopRecording → raw=${rawBytes.size}b denoised=${denoisedBytes.size}b"
    )
    result.success(denoisedBytes)
  }

  // ─────────────────────────────────────────────
  // TRANSCRIPTION
  // ─────────────────────────────────────────────

  private fun handleTranscribeAudio(audioBytes: ByteArray, result: MethodChannel.Result) {
    if (!isModelReady) {
      result.error("MODEL_NOT_LOADED", "Call loadModel() before transcribeAudio()", null)
      return
    }

    // TODO(S3.3-Obj6): Pass audioBytes through Whisper-tiny INT8
    android.util.Log.d("AiChannel", "transcribeAudio → stub (${audioBytes.size} bytes)")
    result.success("نص تجريبي — Whisper stub")
  }

  // ─────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────

  fun dispose() {
    isRecording = false
    audioRecord?.stop()
    audioRecord?.release()
    audioRecord = null
    RNNoiseProcessor.release()
    channel.setMethodCallHandler(null)
  }
}
