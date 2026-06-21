package me.alfuad.securely

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.IvParameterSpec

class SecureStorageHelper(context: Context) {
    private val PREFS_NAME = "securely_storage"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"

    private val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val keyStore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    @Synchronized
    private fun getOrCreateSecretKey(algorithm: String, keySize: String): SecretKey {
        val sizeBits = if (keySize == "bits128") 128 else 256
        val keyAlias = "securely_key_${algorithm}_$keySize"

        if (keyStore.containsAlias(keyAlias)) {
            val entry = keyStore.getEntry(keyAlias, null) as? KeyStore.SecretKeyEntry
            if (entry != null) {
                return entry.secretKey
            }
        }

        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        
        val blockMode = if (algorithm == "aesCbc") KeyProperties.BLOCK_MODE_CBC else KeyProperties.BLOCK_MODE_GCM
        val padding = if (algorithm == "aesCbc") KeyProperties.ENCRYPTION_PADDING_PKCS7 else KeyProperties.ENCRYPTION_PADDING_NONE

        val spec = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setKeySize(sizeBits)
            .setBlockModes(blockMode)
            .setEncryptionPaddings(padding)
            .setRandomizedEncryptionRequired(true)
            .build()
        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    fun write(key: String, value: String, algorithm: String, keySize: String): Boolean {
        return try {
            val secretKey = getOrCreateSecretKey(algorithm, keySize)
            val transformation = if (algorithm == "aesCbc") "AES/CBC/PKCS7Padding" else "AES/GCM/NoPadding"
            val cipher = Cipher.getInstance(transformation)
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)

            val iv = cipher.iv
            val encryptedBytes = cipher.doFinal(value.toByteArray(Charsets.UTF_8))

            val encryptedBase64 = Base64.encodeToString(encryptedBytes, Base64.NO_WRAP)
            val ivBase64 = Base64.encodeToString(iv, Base64.NO_WRAP)

            val storageKey = "${key}_${algorithm}_${keySize}"
            sharedPreferences.edit()
                .putString("${storageKey}_val", encryptedBase64)
                .putString("${storageKey}_iv", ivBase64)
                .commit()
        } catch (e: Exception) {
            false
        }
    }

    fun read(key: String, algorithm: String, keySize: String): String? {
        val storageKey = "${key}_${algorithm}_${keySize}"
        val encryptedBase64 = sharedPreferences.getString("${storageKey}_val", null) ?: return null
        val ivBase64 = sharedPreferences.getString("${storageKey}_iv", null) ?: return null

        return try {
            val encryptedBytes = Base64.decode(encryptedBase64, Base64.NO_WRAP)
            val ivBytes = Base64.decode(ivBase64, Base64.NO_WRAP)

            val secretKey = getOrCreateSecretKey(algorithm, keySize)
            val transformation = if (algorithm == "aesCbc") "AES/CBC/PKCS7Padding" else "AES/GCM/NoPadding"
            val cipher = Cipher.getInstance(transformation)

            if (algorithm == "aesCbc") {
                val spec = IvParameterSpec(ivBytes)
                cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
            } else {
                val spec = GCMParameterSpec(128, ivBytes)
                cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
            }

            val decryptedBytes = cipher.doFinal(encryptedBytes)
            String(decryptedBytes, Charsets.UTF_8)
        } catch (e: Exception) {
            null
        }
    }

    fun delete(key: String, algorithm: String, keySize: String): Boolean {
        val storageKey = "${key}_${algorithm}_${keySize}"
        return sharedPreferences.edit()
            .remove("${storageKey}_val")
            .remove("${storageKey}_iv")
            .commit()
    }

    fun contains(key: String, algorithm: String, keySize: String): Boolean {
        val storageKey = "${key}_${algorithm}_${keySize}"
        return sharedPreferences.contains("${storageKey}_val") && sharedPreferences.contains("${storageKey}_iv")
    }

    fun clear(): Boolean {
        return sharedPreferences.edit().clear().commit()
    }
}
