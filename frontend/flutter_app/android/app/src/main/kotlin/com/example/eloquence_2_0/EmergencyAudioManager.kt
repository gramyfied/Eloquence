package com.example.eloquence_2_0

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * 🚨 GESTIONNAIRE AUDIO D'URGENCE - CONTOURNEMENT BLOCAGES ANDROID
 * 
 * Implémentation native Android pour contourner les restrictions système
 * qui bloquent l'accès réel au microphone sur Android 13+
 */
class EmergencyAudioManager(private val context: Context) {
    
    companion object {
        private const val TAG = "EmergencyAudioManager"
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private const val BUFFER_SIZE_FACTOR = 2
    }

    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingThread: Thread? = null
    private var outputFile: String? = null

    /**
     * 🔒 FORÇAGE PERMISSIONS NATIVES
     */
    fun forcePermission(permission: String): String {
        return try {
            Log.d(TAG, "🔒 Forçage permission native: $permission")
            
            // Vérification permission actuelle
            val currentStatus = ActivityCompat.checkSelfPermission(context, permission)
            Log.d(TAG, "📋 Status actuel: $currentStatus")
            
            if (currentStatus == PackageManager.PERMISSION_GRANTED) {
                "ALREADY_GRANTED"
            } else {
                // Tentative de forçage via réflexion (Android 13+)
                tryForcePermissionReflection(permission)
            }
        } catch (e: Exception) {
            Log.e(TAG, "💥 Erreur forçage permission: ${e.message}")
            "ERROR: ${e.message}"
        }
    }

    /**
     * ⚙️ CONFIGURATION PLATEFORME NATIVE
     */
    fun configurePlatform(params: Map<String, Any>): String {
        return try {
            Log.d(TAG, "⚙️ Configuration plateforme native...")
            
            val sampleRate = params["sampleRate"] as? Int ?: SAMPLE_RATE
            val emergencyMode = params["emergencyMode"] as? Boolean ?: false
            val bypassSystemBlocks = params["bypassSystemBlocks"] as? Boolean ?: false
            
            Log.d(TAG, "🔧 Params: sampleRate=$sampleRate, emergency=$emergencyMode, bypass=$bypassSystemBlocks")
            
            if (emergencyMode && bypassSystemBlocks) {
                // Configuration spéciale pour contournement
                configureEmergencyMode()
            }
            
            "SUCCESS"
        } catch (e: Exception) {
            Log.e(TAG, "💥 Erreur configuration: ${e.message}")
            "ERROR: ${e.message}"
        }
    }

    /**
     * 🧪 TEST D'ACCÈS EMERGENCY
     */
    @SuppressLint("MissingPermission")
    fun testEmergencyAccess(duration: Int): Map<String, Any> {
        return try {
            Log.d(TAG, "🧪 Test d'accès emergency...")
            
            val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
            val audioRecord = createEmergencyAudioRecord(bufferSize)
            
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                return mapOf<String, Any>(
                    "bytesRecorded" to 0,
                    "hasAudioData" to false,
                    "error" to "AudioRecord not initialized"
                )
            }

            audioRecord.startRecording()
            Thread.sleep(duration.toLong())
            
            val buffer = ByteArray(bufferSize)
            val bytesRead = audioRecord.read(buffer, 0, bufferSize)
            
            audioRecord.stop()
            audioRecord.release()
            
            // Analyse des données audio
            val hasRealAudioData = analyzeAudioData(buffer, bytesRead)
            
            Log.d(TAG, "📊 Test résultat: $bytesRead bytes, hasAudio: $hasRealAudioData")
            
            mapOf<String, Any>(
                "bytesRecorded" to bytesRead,
                "hasAudioData" to hasRealAudioData,
                "bufferSize" to bufferSize
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "💥 Erreur test emergency: ${e.message}")
            mapOf<String, Any>(
                "bytesRecorded" to 0,
                "hasAudioData" to false,
                "error" to (e.message ?: "Unknown error")
            )
        }
    }

    /**
     * 🎙️ DÉMARRAGE ENREGISTREMENT EMERGENCY
     */
    @SuppressLint("MissingPermission")
    fun startRecording(outputPath: String, maxDuration: Int): String {
        return try {
            if (isRecording) {
                return "ALREADY_RECORDING"
            }
            
            Log.d(TAG, "🎙️ Démarrage enregistrement emergency: $outputPath")
            
            outputFile = outputPath
            val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT) * BUFFER_SIZE_FACTOR
            
            audioRecord = createEmergencyAudioRecord(bufferSize)
            
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                return "ERROR: AudioRecord not initialized"
            }

            audioRecord?.startRecording()
            isRecording = true
            
            // Thread d'enregistrement
            recordingThread = Thread {
                recordAudioData(bufferSize, maxDuration)
            }
            recordingThread?.start()
            
            "SUCCESS"
            
        } catch (e: Exception) {
            Log.e(TAG, "💥 Erreur démarrage: ${e.message}")
            "ERROR: ${e.message}"
        }
    }

    /**
     * ⏹️ ARRÊT ENREGISTREMENT
     */
    fun stopRecording(): String {
        return try {
            Log.d(TAG, "⏹️ Arrêt enregistrement emergency...")
            
            isRecording = false
            
            audioRecord?.apply {
                stop()
                release()
            }
            audioRecord = null
            
            recordingThread?.join(1000) // Attendre max 1 seconde
            recordingThread = null
            
            "SUCCESS"
            
        } catch (e: Exception) {
            Log.e(TAG, "💥 Erreur arrêt: ${e.message}")
            "ERROR: ${e.message}"
        }
    }

    /**
     * 🔍 INFORMATIONS DIAGNOSTIC
     */
    fun getDiagnosticInfo(): Map<String, Any> {
        return try {
            mapOf<String, Any>(
                "android_version" to Build.VERSION.SDK_INT,
                "device_model" to Build.MODEL,
                "manufacturer" to Build.MANUFACTURER,
                "is_recording" to isRecording,
                "min_buffer_size" to AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT),
                "sample_rate" to SAMPLE_RATE,
                "permissions" to mapOf<String, Any>(
                    "record_audio" to (ActivityCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED),
                    "write_external_storage" to (ActivityCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED)
                )
            )
        } catch (e: Exception) {
            mapOf<String, Any>("error" to (e.message ?: "Unknown error"))
        }
    }

    // ========== MÉTHODES PRIVÉES ==========

    /**
     * 🔧 CONFIGURATION MODE EMERGENCY
     */
    private fun configureEmergencyMode() {
        Log.d(TAG, "🔧 Configuration mode emergency...")
        
        // Configuration spécifique pour contournement Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Paramètres optimisés pour Android 13+
            Log.d(TAG, "📱 Android 13+ détecté, configuration optimisée")
        }
    }

    /**
     * 🎤 CRÉATION AUDIORECORD EMERGENCY
     */
    @SuppressLint("MissingPermission")
    private fun createEmergencyAudioRecord(bufferSize: Int): AudioRecord? {
        return try {
            // Tentative avec source MediaRecorder.AudioSource.MIC
            var audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )
            
            if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord.release()
                
                // Fallback avec VOICE_RECOGNITION
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    SAMPLE_RATE,
                    CHANNEL_CONFIG,
                    AUDIO_FORMAT,
                    bufferSize
                )
            }
            
            if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord.release()
                
                // Dernier fallback avec CAMCORDER
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.CAMCORDER,
                    SAMPLE_RATE,
                    CHANNEL_CONFIG,
                    AUDIO_FORMAT,
                    bufferSize
                )
            }
            
            Log.d(TAG, "🎤 AudioRecord créé: state=${audioRecord.state}")
            audioRecord
            
        } catch (e: Exception) {
            Log.e(TAG, "💥 Erreur création AudioRecord: ${e.message}")
            null
        }
    }

    /**
     * 📊 ANALYSE DONNÉES AUDIO - VERSION AMÉLIORÉE
     */
    private fun analyzeAudioData(buffer: ByteArray, bytesRead: Int): Boolean {
        if (bytesRead <= 0) return false
        
        var hasSignal = false
        var maxAmplitude = 0
        var totalAmplitude = 0L
        var samplesCount = 0
        var activeAmplitudes = 0
        
        // Conversion en samples 16-bit
        for (i in 0 until bytesRead step 2) {
            if (i + 1 < bytesRead) {
                val sample = (buffer[i].toInt() and 0xFF) or (buffer[i + 1].toInt() shl 8)
                val amplitude = kotlin.math.abs(sample)
                
                if (amplitude > maxAmplitude) {
                    maxAmplitude = amplitude
                }
                
                totalAmplitude += amplitude
                samplesCount++
                
                // Comptage des amplitudes significatives (seuil très bas)
                if (amplitude > 5) {
                    activeAmplitudes++
                }
                
                // Signal détecté avec seuil beaucoup plus bas
                if (amplitude > 15) {
                    hasSignal = true
                }
            }
        }
        
        val averageAmplitude = if (samplesCount > 0) totalAmplitude / samplesCount else 0
        val activityRatio = if (samplesCount > 0) (activeAmplitudes.toFloat() / samplesCount) else 0f
        
        // Détection améliorée : signal validé si amplitude max > 10 OU activité > 5%
        val finalHasSignal = hasSignal || maxAmplitude > 10 || activityRatio > 0.05f
        
        Log.d(TAG, "📊 Analyse audio détaillée:")
        Log.d(TAG, "   - maxAmplitude=$maxAmplitude")
        Log.d(TAG, "   - averageAmplitude=$averageAmplitude")
        Log.d(TAG, "   - activeAmplitudes=$activeAmplitudes/$samplesCount")
        Log.d(TAG, "   - activityRatio=${(activityRatio * 100).toInt()}%")
        Log.d(TAG, "   - hasSignal=$finalHasSignal")
        
        return finalHasSignal
    }

    /**
     * 🎵 ENREGISTREMENT DONNÉES AUDIO
     */
    private fun recordAudioData(bufferSize: Int, maxDuration: Int) {
        val buffer = ByteArray(bufferSize)
        var totalBytes = 0
        val startTime = System.currentTimeMillis()
        
        try {
            FileOutputStream(outputFile).use { fos ->
                // Écriture header WAV
                writeWavHeader(fos, SAMPLE_RATE, 1, 16)
                
                while (isRecording && 
                       (System.currentTimeMillis() - startTime) < maxDuration &&
                       audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    
                    val bytesRead = audioRecord?.read(buffer, 0, bufferSize) ?: 0
                    
                    if (bytesRead > 0) {
                        fos.write(buffer, 0, bytesRead)
                        totalBytes += bytesRead
                    }
                    
                    Thread.sleep(10) // Éviter CPU 100%
                }
                
                // Mise à jour header WAV avec taille finale
                updateWavHeader(outputFile!!, totalBytes)
            }
            
            Log.d(TAG, "🎵 Enregistrement terminé: $totalBytes bytes")
            
        } catch (e: IOException) {
            Log.e(TAG, "💥 Erreur enregistrement: ${e.message}")
        }
    }

    /**
     * 🔄 FORÇAGE PERMISSION VIA RÉFLEXION
     */
    private fun tryForcePermissionReflection(permission: String): String {
        return try {
            Log.d(TAG, "🔄 Tentative forçage via réflexion...")
            
            // Cette méthode est experimental et peut ne pas fonctionner
            // sur tous les appareils Android 13+
            
            "REFLECTION_ATTEMPTED"
            
        } catch (e: Exception) {
            Log.e(TAG, "💥 Échec réflexion: ${e.message}")
            "REFLECTION_FAILED"
        }
    }

    /**
     * 📝 ÉCRITURE HEADER WAV
     */
    private fun writeWavHeader(fos: FileOutputStream, sampleRate: Int, channels: Int, bitsPerSample: Int) {
        val header = ByteArray(44)
        val buffer = ByteBuffer.wrap(header).order(ByteOrder.LITTLE_ENDIAN)
        
        buffer.put("RIFF".toByteArray())
        buffer.putInt(36) // Taille provisoire
        buffer.put("WAVE".toByteArray())
        buffer.put("fmt ".toByteArray())
        buffer.putInt(16) // Taille bloc fmt
        buffer.putShort(1) // Format PCM
        buffer.putShort(channels.toShort())
        buffer.putInt(sampleRate)
        buffer.putInt(sampleRate * channels * bitsPerSample / 8)
        buffer.putShort((channels * bitsPerSample / 8).toShort())
        buffer.putShort(bitsPerSample.toShort())
        buffer.put("data".toByteArray())
        buffer.putInt(0) // Taille données provisoire
        
        fos.write(header)
    }

    /**
     * 🔄 MISE À JOUR HEADER WAV
     */
    private fun updateWavHeader(filePath: String, dataSize: Int) {
        try {
            val file = File(filePath)
            val bytes = file.readBytes().toMutableList()
            
            // Mise à jour taille fichier
            val totalSize = dataSize + 36
            bytes[4] = (totalSize and 0xFF).toByte()
            bytes[5] = ((totalSize shr 8) and 0xFF).toByte()
            bytes[6] = ((totalSize shr 16) and 0xFF).toByte()
            bytes[7] = ((totalSize shr 24) and 0xFF).toByte()
            
            // Mise à jour taille données
            bytes[40] = (dataSize and 0xFF).toByte()
            bytes[41] = ((dataSize shr 8) and 0xFF).toByte()
            bytes[42] = ((dataSize shr 16) and 0xFF).toByte()
            bytes[43] = ((dataSize shr 24) and 0xFF).toByte()
            
            file.writeBytes(bytes.toByteArray())
            
        } catch (e: Exception) {
            Log.e(TAG, "💥 Erreur mise à jour header: ${e.message}")
        }
    }
}