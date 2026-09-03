package com.example.transturc;

import android.content.Intent;
import android.os.Bundle;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.Locale;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "com.example.transturc/voice";
  private SpeechRecognizer speechRecognizer;
  private TextToSpeech textToSpeech;
  private MethodChannel.Result pendingResult;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler(this::handleVoiceCall);
  }

  private void handleVoiceCall(MethodCall call, MethodChannel.Result result) {
    switch (call.method) {
      case "initialize":
        boolean available = SpeechRecognizer.isRecognitionAvailable(this);
        textToSpeech = new TextToSpeech(this, status -> {});
        result.success(available);
        break;
      case "startListening":
        startListening((String) call.argument("localeId"));
        result.success(null);
        break;
      case "stopListening":
        if (speechRecognizer != null) speechRecognizer.stopListening();
        result.success(null);
        break;
      case "speak":
        if (textToSpeech != null) {
          String localeId = (String) call.argument("localeId");
          textToSpeech.setLanguage(Locale.forLanguageTag(localeId));
          textToSpeech.speak((String) call.argument("text"), TextToSpeech.QUEUE_FLUSH, null, "anla-tts");
        }
        result.success(null);
        break;
      case "stopSpeaking":
        if (textToSpeech != null) textToSpeech.stop();
        result.success(null);
        break;
      default:
        result.notImplemented();
    }
  }

  private void startListening(String localeId) {
    if (speechRecognizer != null) speechRecognizer.destroy();
    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this);
    speechRecognizer.setRecognitionListener(new RecognitionListener() {
      @Override public void onResults(Bundle results) {
        ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
        if (matches != null && !matches.isEmpty()) {
          new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
              .invokeMethod("speechResult", java.util.Collections.singletonMap("text", matches.get(0)));
        }
      }
      @Override public void onError(int error) {}
      @Override public void onReadyForSpeech(Bundle params) {}
      @Override public void onBeginningOfSpeech() {}
      @Override public void onRmsChanged(float rmsdB) {}
      @Override public void onBufferReceived(byte[] buffer) {}
      @Override public void onEndOfSpeech() {}
      @Override public void onPartialResults(Bundle partialResults) {}
      @Override public void onEvent(int eventType, Bundle params) {}
    });
    Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
    intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId);
    intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
    intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true);
    speechRecognizer.startListening(intent);
  }

  @Override
  protected void onDestroy() {
    if (speechRecognizer != null) speechRecognizer.destroy();
    if (textToSpeech != null) textToSpeech.shutdown();
    super.onDestroy();
  }
}
