package com.tazakar.tazakar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

  private var aiChannelHandler: AiChannelHandler? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    aiChannelHandler = AiChannelHandler(this, flutterEngine)
  }

  override fun onDestroy() {
    aiChannelHandler?.dispose()
    aiChannelHandler = null
    super.onDestroy()
  }
}
