import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

  // MARK: - Properties

  private var audioRecorder: AVAudioRecorder?
  private var recordingURL: URL?
  private var isModelReady = false

  // MARK: - App Lifecycle

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  // MARK: - FlutterAppDelegate channel registration

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Called by Flutter engine once the view controller is available
  func registerChannels(with registrar: FlutterPluginRegistrar) {
    setupAiChannel(binaryMessenger: registrar.messenger())
  }

  // MARK: - Platform Channel Setup

  func setupAiChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.tazakar.app/ai_channel",
      binaryMessenger: binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "loadModel":
        self.handleLoadModel(result: result)

      case "isModelLoaded":
        result(self.isModelReady)

      case "startRecording":
        self.handleStartRecording(result: result)

      case "stopRecording":
        self.handleStopRecording(result: result)

      case "transcribeAudio":
        guard let args = call.arguments as? [String: Any],
              let audioBytes = args["audioBytes"] as? FlutterStandardTypedData
        else {
          result(FlutterError(
            code: "INVALID_ARGS",
            message: "audioBytes is required",
            details: nil
          ))
          return
        }
        self.handleTranscribeAudio(audioData: audioBytes.data, result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Model Management

  private func handleLoadModel(result: FlutterResult) {
    isModelReady = true
    NSLog("[AiChannel] loadModel → stub ready")
    result(true)
  }

  // MARK: - Audio Recording

  private func handleStartRecording(result: @escaping FlutterResult) {
    AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
      guard let self = self else { return }
      guard granted else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "PERMISSION_DENIED",
            message: "Microphone permission denied",
            details: nil
          ))
        }
        return
      }

      do {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true)

        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("tazakar_recording.wav")
        self.recordingURL = url

        let settings: [String: Any] = [
          AVFormatIDKey: Int(kAudioFormatLinearPCM),
          AVSampleRateKey: 16000,
          AVNumberOfChannelsKey: 1,
          AVLinearPCMBitDepthKey: 16,
          AVLinearPCMIsFloatKey: false,
          AVLinearPCMIsBigEndianKey: false,
        ]

        self.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        self.audioRecorder?.record()

        NSLog("[AiChannel] startRecording → started at \(url.path)")
        DispatchQueue.main.async { result(true) }

      } catch {
        NSLog("[AiChannel] startRecording error: \(error)")
        DispatchQueue.main.async {
          result(FlutterError(
            code: "RECORDING_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private func handleStopRecording(result: FlutterResult) {
    guard let recorder = audioRecorder, recorder.isRecording else {
      result(FlutterError(
        code: "NOT_RECORDING",
        message: "No active recording to stop",
        details: nil
      ))
      return
    }

    recorder.stop()
    audioRecorder = nil

    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      NSLog("[AiChannel] AVAudioSession deactivation error: \(error)")
    }

    guard let url = recordingURL,
          let audioData = try? Data(contentsOf: url)
    else {
      result(FlutterError(
        code: "READ_ERROR",
        message: "Could not read recorded audio file",
        details: nil
      ))
      return
    }

    NSLog("[AiChannel] stopRecording → \(audioData.count) bytes")
    result(FlutterStandardTypedData(bytes: audioData))
  }

  // MARK: - Transcription

  private func handleTranscribeAudio(audioData: Data, result: FlutterResult) {
    guard isModelReady else {
      result(FlutterError(
        code: "MODEL_NOT_LOADED",
        message: "Call loadModel() before transcribeAudio()",
        details: nil
      ))
      return
    }

    NSLog("[AiChannel] transcribeAudio → stub (\(audioData.count) bytes received)")
    result("نص تجريبي — Whisper stub")
  }
}
