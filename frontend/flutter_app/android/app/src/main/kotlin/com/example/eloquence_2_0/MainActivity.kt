package com.example.eloquence_2_0

import android.content.Context
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.bluetooth.BluetoothAdapter
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.VolumeProvider
import android.provider.Settings
import android.os.Vibrator
import android.os.VibrationEffect
import android.app.NotificationManager 
import android.util.Log 
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.media.AudioAttributes 

class MainActivity: FlutterActivity() {
    private val CHANNEL_NATIVE_CHECK = "com.example.eloquence_2_0/native_check"
    private val CHANNEL_AUDIO_DIAGNOSTIC = "eloquence/audio"
    private val CHANNEL_AUDIO_NATIVE = "eloquence.audio/native"
    private val CHANNEL_EMERGENCY_AUDIO = "com.eloquence.emergency_audio"

    private lateinit var audioManager: AudioManager
    private lateinit var notificationManager: NotificationManager
    private var headsetPlugReceiver: BroadcastReceiver? = null
    private lateinit var emergencyAudioManager: EmergencyAudioManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        emergencyAudioManager = EmergencyAudioManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NATIVE_CHECK).setMethodCallHandler { call, result ->
            if (call.method == "checkNativeLibraries") {
                result.success(checkNativeLibraries())
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_AUDIO_DIAGNOSTIC).setMethodCallHandler { call, result ->
            CoroutineScope(Dispatchers.Main).launch {
                when (call.method) {
                    "getAudioInfo" -> result.success(getAudioInfo())
                    "getSystemVolume" -> result.success(getSystemVolume())
                    "getMediaVolume" -> result.success(getMediaVolume())
                    "getMaxVolume" -> result.success(getMaxVolume())
                    "getRingerMode" -> result.success(getRingerMode())
                    "getMode" -> result.success(getAudioModeInt()) 
                    "getDoNotDisturbMode" -> result.success(getDoNotDisturbMode())
                    "getCurrentAudioOutput" -> result.success(getCurrentAudioOutput())
                    "getAvailableAudioOutputs" -> result.success(getAvailableAudioOutputs())
                    "setSpeakerphoneOn" -> {
                        val args = call.arguments as? Map<String, Any?>
                        val on = args?.get("on") as? Boolean ?: false
                        setSpeakerphoneOn(on)
                        Log.d("MainActivity", "Speakerphone set to: $on. Current isSpeakerphoneOn: ${audioManager.isSpeakerphoneOn}")
                        result.success(null)
                    }
                    "setStreamVolume" -> {
                        val args = call.arguments as? Map<String, Any?>
                        val streamType = args?.get("streamType") as? Int ?: AudioManager.STREAM_MUSIC
                        val volume = args?.get("volume") as? Int ?: 0
                        val flags = args?.get("flags") as? Int ?: 0
                        setStreamVolume(streamType, volume, flags)
                        result.success(null)
                    }
                    "setMode" -> {
                        val args = call.arguments as? Map<String, Any?>
                        val mode = args?.get("mode") as? Int ?: AudioManager.MODE_NORMAL
                        setAudioMode(mode)
                        result.success(null)
                    }
                    "isSpeakerphoneOn" -> result.success(isSpeakerphoneOn())
                    "isBluetoothConnected" -> result.success(isBluetoothConnected())
                    "isHeadsetConnected" -> result.success(isHeadsetConnected())
                    "getAudioDevices" -> result.success(getAudioDevices())
                    "hasAudioFocus" -> result.success(hasAudioFocus())
                    "requestAudioFocus" -> result.success(requestAudioFocus())
                    "setMediaVolumeMax" -> {
                        setMediaVolumeMax()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Channel pour les méthodes audio spécifiques à Eloquence
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_AUDIO_NATIVE).setMethodCallHandler { call, result ->
            when (call.method) {
                "configureAudioForSpeech" -> {
                    configureAudioForSpeech()
                    result.success(true)
                }
                "setAudioToSpeaker" -> {
                    setAudioToSpeaker()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 🚨 CANAL EMERGENCY AUDIO - CONTOURNEMENT BLOCAGES ANDROID
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_EMERGENCY_AUDIO).setMethodCallHandler { call, result ->
            CoroutineScope(Dispatchers.Main).launch {
                try {
                    when (call.method) {
                        "forcePermission" -> {
                            val args = call.arguments as? Map<String, Any?>
                            val permission = args?.get("permission") as? String ?: ""
                            val forceResult = emergencyAudioManager.forcePermission(permission)
                            result.success(forceResult)
                        }
                        "configurePlatform" -> {
                            val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                            // Convertir Map<String, Any?> vers Map<String, Any> en filtrant les valeurs null
                            val safeArgs = args.filterValues { it != null }.mapValues { it.value!! }
                            val configResult = emergencyAudioManager.configurePlatform(safeArgs)
                            result.success(configResult)
                        }
                        "testEmergencyAccess" -> {
                            val args = call.arguments as? Map<String, Any?>
                            val duration = args?.get("duration") as? Int ?: 1000
                            val testResult = emergencyAudioManager.testEmergencyAccess(duration)
                            result.success(testResult)
                        }
                        "startRecording" -> {
                            val args = call.arguments as? Map<String, Any?>
                            val outputPath = args?.get("outputPath") as? String ?: ""
                            val maxDuration = args?.get("maxDuration") as? Int ?: 30000
                            val startResult = emergencyAudioManager.startRecording(outputPath, maxDuration)
                            result.success(startResult)
                        }
                        "stopRecording" -> {
                            val stopResult = emergencyAudioManager.stopRecording()
                            result.success(stopResult)
                        }
                        "getDiagnosticInfo" -> {
                            val diagnosticInfo = emergencyAudioManager.getDiagnosticInfo()
                            result.success(diagnosticInfo)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e("MainActivity", "🚨 Erreur emergency audio: ${e.message}", e)
                    result.error("EMERGENCY_ERROR", e.message, null)
                }
            }
        }
    }

    //region Native Library Checks (existing)
    private fun checkNativeLibraries(): Map<String, Any> {
        val results = mutableMapOf<String, Any>()

        try {
            val libDirs = listOf(
                applicationInfo.nativeLibraryDir,
                "/system/lib",
                "/system/lib64",
                "/vendor/lib",
                "/vendor/lib64"
            )
            results["nativeLibraryDir"] = applicationInfo.nativeLibraryDir
            results["libDirs"] = libDirs

            val webrtcLibs = listOf(
                "libjingle_peerconnection_so.so",
                "libwebrtc.so"
            )
            val foundLibs = mutableListOf<String>()
            val missingLibs = mutableListOf<String>()

            for (libName in webrtcLibs) {
                var found = false
                for (dir in libDirs) {
                    val libFile = File(dir, libName)
                    if (libFile.exists()) {
                        foundLibs.add("$dir/$libName")
                        found = true
                        break
                    }
                }
                if (!found) {
                    missingLibs.add(libName)
                }
            }
            results["foundLibs"] = foundLibs
            results["missingLibs"] = missingLibs

            var magtSyncFound = false
            for (dir in libDirs) {
                val magtSyncFile = File(dir, "libmagtsync.so")
                if (magtSyncFile.exists()) {
                    results["libmagtsync_location"] = "$dir/libmagtsync.so"
                    magtSyncFound = true
                    break
                }
            }
            if (!magtSyncFound) {
                results["libmagtsync_location"] = "NOT FOUND"
            }
            results["supportedAbis"] = Build.SUPPORTED_ABIS.toList()
            results["primaryAbi"] = Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"

        } catch (e: Exception) {
            results["error"] = e.message ?: "Unknown error"
        }
        return results
    }
    //endregion

    //region Audio Diagnostics Methods (new implementations and existing extensions)
    private fun getAudioInfo(): Map<String, Any> {
        val info = mutableMapOf<String, Any>()
        info["streamVolume"] = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        info["maxVolume"] = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        info["isSpeakerphoneOn"] = audioManager.isSpeakerphoneOn
        info["isHeadsetOn"] = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioManager.getDevices(AudioManager.GET_DEVICES_ALL)
                .any { it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET || it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES }
        } else {
            @Suppress("DEPRECATION")
            audioManager.isWiredHeadsetOn
        }
        info["isBluetoothA2dpOn"] = audioManager.isBluetoothA2dpOn
        info["mode"] = getAudioMode()
        info["ringerMode"] = getRingerMode()
        info["voiceCallVolume"] = audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL)
        info["maxVoiceCallVolume"] = audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
        return info
    }

    private fun getSystemVolume(): Int {
        return audioManager.getStreamVolume(AudioManager.STREAM_SYSTEM)
    }

    private fun getMediaVolume(): Int {
        return audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
    }

    private fun getMaxVolume(): Int {
        return audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    }

    private fun getRingerMode(): String {
        return when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_NORMAL -> "normal"
            AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            else -> "unknown"
        }
    }

    private fun getAudioModeInt(): Int { 
        return audioManager.mode
    }

    private fun setAudioMode(mode: Int) {
        audioManager.mode = mode
    }
    
    private fun getAudioMode(): String {
        return when (audioManager.mode) {
            AudioManager.MODE_NORMAL -> "normal"
            AudioManager.MODE_RINGTONE -> "ringtone"
            AudioManager.MODE_IN_CALL -> "in_call"
            AudioManager.MODE_IN_COMMUNICATION -> "in_communication"
            else -> "unknown"
        }
    }

    private fun getDoNotDisturbMode(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val notificationPolicyAccessGranted = notificationManager.isNotificationPolicyAccessGranted
            if (notificationPolicyAccessGranted) {
                return when (notificationManager.currentInterruptionFilter) {
                    NotificationManager.INTERRUPTION_FILTER_ALL -> "none"
                    NotificationManager.INTERRUPTION_FILTER_PRIORITY -> "priority_only"
                    NotificationManager.INTERRUPTION_FILTER_ALARMS -> "alarms_only"
                    NotificationManager.INTERRUPTION_FILTER_NONE -> "total_silence"
                    else -> "unknown"
                }
            } else {
                return "permission_denied"
            }
        }
        return "not_supported"
    }
    
    private fun getCurrentAudioOutput(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }?.let { "earpiece" }
                ?: devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }?.let { "speaker" }
                ?: devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP }?.let { "bluetooth" }
                ?: devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES || it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET }?.let { "headset" }
                ?: "unknown"
        } else {
            @Suppress("DEPRECATION")
            if (audioManager.isSpeakerphoneOn) "speaker"
            else if (audioManager.isBluetoothA2dpOn) "bluetooth"
            else if (audioManager.isWiredHeadsetOn) "headset"
            else "earpiece" 
        }
    }

    private fun getAvailableAudioOutputs(): List<String> {
        val outputs = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                when (device.type) {
                    AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> outputs.add("earpiece")
                    AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> outputs.add("speaker")
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> outputs.add("bluetooth_a2dp")
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> outputs.add("bluetooth_sco")
                    AudioDeviceInfo.TYPE_USB_HEADSET -> outputs.add("usb_headset")
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> outputs.add("wired_headphones")
                    AudioDeviceInfo.TYPE_WIRED_HEADSET -> outputs.add("wired_headset")
                    AudioDeviceInfo.TYPE_UNKNOWN -> {} 
                    else -> {} 
                }
            }
        } else {
            @Suppress("DEPRECATION")
            if (audioManager.isSpeakerphoneOn) outputs.add("speaker")
            @Suppress("DEPRECATION")
            if (audioManager.isBluetoothA2dpOn) outputs.add("bluetooth_a2dp")
            @Suppress("DEPRECATION")
            if (audioManager.isWiredHeadsetOn) outputs.add("wired_headset")
            if (outputs.isEmpty()) outputs.add("earpiece") 
        }
        return outputs.distinct() 
    }

    private fun setSpeakerphoneOn(on: Boolean) {
        audioManager.isSpeakerphoneOn = on
    }

    private fun isSpeakerphoneOn(): Boolean {
        return audioManager.isSpeakerphoneOn
    }
    
    private fun isBluetoothConnected(): Boolean {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            return false
        }
        @Suppress("DEPRECATION")
        val a2dpConnected = bluetoothAdapter.getProfileConnectionState(android.bluetooth.BluetoothProfile.A2DP) == android.bluetooth.BluetoothProfile.STATE_CONNECTED
        @Suppress("DEPRECATION")
        val scoConnected = bluetoothAdapter.getProfileConnectionState(android.bluetooth.BluetoothProfile.HEADSET) == android.bluetooth.BluetoothProfile.STATE_CONNECTED
        return a2dpConnected || scoConnected
    }


    private fun isHeadsetConnected(): Boolean {
        @Suppress("DEPRECATION")
        return audioManager.isWiredHeadsetOn
    }

    private fun unregisterHeadsetPlugReceiver() {
        if (headsetPlugReceiver != null) {
            try {
                applicationContext.unregisterReceiver(headsetPlugReceiver)
            } catch (e: IllegalArgumentException) {
            }
            headsetPlugReceiver = null
        }
    }

    override fun onResume() {
        super.onResume()
    }

    override fun onPause() {
        super.onPause()
    }

    private fun getAudioDevices(): List<Map<String, Any>> {
        val devices = mutableListOf<Map<String, Any>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val audioDevices = audioManager.getDevices(AudioManager.GET_DEVICES_ALL)
            for (device in audioDevices) {
                devices.add(mapOf(
                    "type" to device.type.toString(),
                    "productName" to (device.productName ?: "").toString(),
                    "isSink" to device.isSink,
                    "isSource" to device.isSource
                ))
            }
        }
        return devices
    }

    private var audioFocusChangeListener: AudioManager.OnAudioFocusChangeListener? = null

    private fun hasAudioFocus(): Boolean {
        return true 
    }

    private var focusRequest: AudioFocusRequest? = null 

    private fun requestAudioFocus(): Boolean {
        if (audioFocusChangeListener == null) {
            audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
                when (focusChange) {
                    AudioManager.AUDIOFOCUS_GAIN -> {
                    }
                    AudioManager.AUDIOFOCUS_LOSS -> {
                    }
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                    }
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                    }
                }
            }
        }

        val result: Int
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setWillPauseWhenDucked(true)
                .setOnAudioFocusChangeListener(audioFocusChangeListener!!)
                .build()
            result = audioManager.requestAudioFocus(focusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            result = audioManager.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_VOICE_CALL, 
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
            )
        }
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun setMediaVolumeMax() { 
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume, 0)
    }

    private fun setStreamVolume(streamType: Int, volume: Int, flags: Int) { 
        audioManager.setStreamVolume(streamType, volume, flags)
    }

    private fun getAudioConfiguration(): Map<String, Any> {
        val audioConfig = mutableMapOf<String, Any>()
        return audioConfig
    }

    // Méthodes spécifiques pour Eloquence audio
    private fun configureAudioForSpeech() {
        try {
            // Configuration pour la communication vocale
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            audioManager.isSpeakerphoneOn = true
            
            // Définir le volume à un niveau optimal
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val optimalVolume = (maxVolume * 0.8).toInt()
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, optimalVolume, 0)
            
            // Demander le focus audio pour la communication
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    .setWillPauseWhenDucked(false)
                    .build()
                audioManager.requestAudioFocus(focusRequest)
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(
                    null,
                    AudioManager.STREAM_VOICE_CALL,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
                )
            }
            
            Log.d("MainActivity", "Audio configuré pour la parole - Mode: ${audioManager.mode}, Speaker: ${audioManager.isSpeakerphoneOn}")
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur configuration audio pour la parole", e)
        }
    }
    
    private fun setAudioToSpeaker() {
        try {
            audioManager.isSpeakerphoneOn = true
            
            // Forcer le routage vers le haut-parleur principal
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                val speaker = devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                if (speaker != null) {
                    // Note: setPreferredDevice n'est pas disponible directement sur AudioManager
                    // mais on peut utiliser setSpeakerphoneOn qui a le même effet
                    audioManager.isSpeakerphoneOn = true
                }
            }
            
            Log.d("MainActivity", "Audio routé vers le haut-parleur - isSpeakerphoneOn: ${audioManager.isSpeakerphoneOn}")
        } catch (e: Exception) {
            Log.e("MainActivity", "Erreur routage audio vers haut-parleur", e)
        }
    }
    //endregion

    override fun onDestroy() {
        super.onDestroy()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && focusRequest != null) {
            audioManager.abandonAudioFocusRequest(focusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            if (audioFocusChangeListener != null) {
                audioManager.abandonAudioFocus(audioFocusChangeListener)
            }
        }
    }
}
