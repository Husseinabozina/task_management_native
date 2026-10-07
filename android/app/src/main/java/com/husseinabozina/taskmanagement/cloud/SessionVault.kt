package com.husseinabozina.taskmanagement.cloud

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import org.json.JSONObject
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

data class CloudSession(val userId: String, val email: String, val accessToken: String,
    val refreshToken: String, val expiresAt: Long) {
    fun json() = JSONObject().put("userId", userId).put("email", email).put("accessToken", accessToken)
        .put("refreshToken", refreshToken).put("expiresAt", expiresAt)

    companion object {
        fun fromAuth(json: JSONObject): CloudSession {
            val user = json.getJSONObject("user")
            java.util.UUID.fromString(user.getString("id"))
            return CloudSession(user.getString("id"), user.optString("email"), json.getString("access_token"),
                json.getString("refresh_token"), System.currentTimeMillis() + json.getLong("expires_in") * 1_000)
        }
    }
}

/** Tokens are AES-GCM encrypted with a non-exportable Keystore key and excluded from backups. */
class SessionVault(context: Context) {
    private val file = AtomicFile(File(context.noBackupFilesDir, "cloud-session.enc"))
    private val alias = "mahami.cloud.session.v1"

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true).build())
        }.generateKey()
    }

    fun read(): CloudSession? {
        if (!file.baseFile.isFile) return null
        val data = file.readFully()
        require(data.size > 12)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, data.copyOfRange(0, 12)))
        val json = JSONObject(cipher.doFinal(data.copyOfRange(12, data.size)).toString(Charsets.UTF_8))
        return CloudSession(json.getString("userId"), json.getString("email"), json.getString("accessToken"),
            json.getString("refreshToken"), json.getLong("expiresAt"))
    }

    fun save(session: CloudSession) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val output = file.startWrite()
        try {
            output.write(cipher.iv + cipher.doFinal(session.json().toString().toByteArray(Charsets.UTF_8)))
            file.finishWrite(output)
        } catch (failure: Exception) { file.failWrite(output); throw failure }
    }

    fun clear() = file.delete()
}
