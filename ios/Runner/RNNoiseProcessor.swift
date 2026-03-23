import Foundation

/// RNNoise audio pre-processor stub.
///
/// Architecture: Audio pipeline is designed as:
///   AVAudioRecorder (16kHz PCM) → RNNoiseProcessor → Whisper-tiny INT8
///
/// Current state (Phase 3.3): Pass-through stub.
/// The interface is stable and drop-in replaceable with real RNNoise in Phase 4.
///
/// Phase 4 implementation notes:
///   - Integrate RNNoise as xcframework (build from xiph/rnnoise source via cmake)
///   - RNNoise operates at 48kHz — resample 16kHz → 48kHz before processing
///   - Process in 480-sample frames (10ms at 48kHz)
///   - Resample output back to 16kHz for Whisper
///   - Use AVAudioConverter for resampling
///
/// SC-01 compliance: All processing on-device, zero data transmitted.
///
/// Decision: OQ-03 resolved (DEC-25, Session 12) — RNNoise selected over
/// platform-native and WebRTC VAD/NS approaches.
final class RNNoiseProcessor {

  static let shared = RNNoiseProcessor()
  private var isInitialised = false

  private init() {}

  // MARK: - Lifecycle

  /// Initialises the RNNoise processor.
  /// Phase 3.3: no-op stub.
  /// Phase 4: load RNNoise xcframework and allocate DenoiseState.
  func initialize() {
    // TODO(Phase4-RNNoise): Load RNNoise.xcframework
    // TODO(Phase4-RNNoise): Allocate rnnoise_create() DenoiseState
    isInitialised = true
    NSLog("[RNNoiseProcessor] initialize → stub (pass-through mode)")
  }

  // MARK: - Processing

  /// Processes raw PCM audio through RNNoise denoising.
  ///
  /// - Parameter pcmData: Raw 16-bit mono PCM at 16kHz
  /// - Returns: Denoised PCM data (same format as input)
  ///
  /// Phase 3.3: Returns input unchanged (pass-through).
  /// Phase 4: Resample → denoise → resample back.
  func process(_ pcmData: Data) -> Data {
    if !isInitialised { initialize() }

    // TODO(Phase4-RNNoise): Resample 16kHz → 48kHz using AVAudioConverter
    // TODO(Phase4-RNNoise): Split into 480-sample frames
    // TODO(Phase4-RNNoise): Call rnnoise_process_frame() for each frame
    // TODO(Phase4-RNNoise): Reassemble frames
    // TODO(Phase4-RNNoise): Resample 48kHz → 16kHz

    NSLog("[RNNoiseProcessor] process → pass-through (\(pcmData.count) bytes)")
    return pcmData
  }

  // MARK: - Cleanup

  /// Releases native resources.
  /// Phase 3.3: no-op stub.
  /// Phase 4: rnnoise_destroy(state).
  func release() {
    // TODO(Phase4-RNNoise): rnnoise_destroy(state)
    isInitialised = false
    NSLog("[RNNoiseProcessor] release → stub")
  }
}
