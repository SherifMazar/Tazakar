package com.tazakar.tazakar

/**
 * RNNoise audio pre-processor stub.
 *
 * Architecture: Audio pipeline is designed as:
 *   AudioRecord (16kHz PCM) → RNNoiseProcessor → Whisper-tiny INT8
 *
 * Current state (Phase 3.3): Pass-through stub.
 * The interface is stable and drop-in replaceable with real RNNoise in Phase 4.
 *
 * Phase 4 implementation notes:
 *   - RNNoise operates at 48kHz — resample 16kHz → 48kHz before processing
 *   - Process in 480-sample frames (10ms at 48kHz)
 *   - Resample output back to 16kHz for Whisper
 *   - Use Android NDK CMake to compile librnnoise.so from xiph/rnnoise source
 *   - Load via System.loadLibrary("rnnoise")
 *
 * SC-01 compliance: All processing on-device, zero data transmitted.
 *
 * Decision: OQ-03 resolved (DEC-25, Session 12) — RNNoise selected over
 * platform-native and WebRTC VAD/NS approaches.
 */
object RNNoiseProcessor {

  private var isInitialised = false

  /**
   * Initialises the RNNoise processor.
   * Phase 3.3: no-op stub.
   * Phase 4: load librnnoise.so and allocate DenoiseState.
   */
  fun init(): Boolean {
    // TODO(Phase4-RNNoise): System.loadLibrary("rnnoise")
    // TODO(Phase4-RNNoise): allocate native DenoiseState via JNI
    isInitialised = true
    android.util.Log.d("RNNoiseProcessor", "init → stub (pass-through mode)")
    return true
  }

  /**
   * Processes raw PCM audio through RNNoise denoising.
   *
   * @param pcmData Raw 16-bit mono PCM at 16kHz
   * @return Denoised PCM data (same format as input)
   *
   * Phase 3.3: Returns input unchanged (pass-through).
   * Phase 4: Resample → denoise → resample back.
   */
  fun process(pcmData: ByteArray): ByteArray {
    if (!isInitialised) init()

    // TODO(Phase4-RNNoise): Resample 16kHz → 48kHz
    // TODO(Phase4-RNNoise): Split into 480-sample frames
    // TODO(Phase4-RNNoise): Call rnnoise_process_frame() for each frame via JNI
    // TODO(Phase4-RNNoise): Reassemble frames
    // TODO(Phase4-RNNoise): Resample 48kHz → 16kHz

    android.util.Log.d(
      "RNNoiseProcessor",
      "process → pass-through (${pcmData.size} bytes)"
    )
    return pcmData
  }

  /**
   * Releases native resources.
   * Phase 3.3: no-op stub.
   * Phase 4: free native DenoiseState via JNI.
   */
  fun release() {
    // TODO(Phase4-RNNoise): rnnoise_destroy(state) via JNI
    isInitialised = false
    android.util.Log.d("RNNoiseProcessor", "release → stub")
  }
}
