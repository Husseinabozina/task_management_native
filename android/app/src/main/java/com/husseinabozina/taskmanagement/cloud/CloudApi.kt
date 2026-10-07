package com.husseinabozina.taskmanagement.cloud

import com.husseinabozina.taskmanagement.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class CloudFailure(val readable: String, val status: Int? = null) : Exception(readable)

/** Supabase Auth + one transaction RPC. No administrator key is accepted in a client build. */
class CloudApi {
    private val base = BuildConfig.SUPABASE_URL.trimEnd('/')
    private val key = BuildConfig.SUPABASE_CLIENT_KEY
    val configured: Boolean = runCatching {
        val url = URL(base)
        url.protocol == "https" && url.host.isNotBlank() && url.userInfo == null && key.isNotBlank() &&
            !key.startsWith("sb_secret_") && (key.startsWith("sb_publishable_") ||
            JSONObject(String(android.util.Base64.decode(key.split('.')[1], android.util.Base64.URL_SAFE or
                android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP))).optString("role") == "anon")
    }.getOrDefault(false)

    suspend fun request(path: String, body: JSONObject = JSONObject(), token: String? = null): JSONObject =
        withContext(Dispatchers.IO) {
            if (!configured) throw CloudFailure("المزامنة غير مهيّأة في هذه النسخة.")
            val connection = URL(base + path).openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "POST"
                connection.instanceFollowRedirects = false
                connection.connectTimeout = 15_000
                connection.readTimeout = 30_000
                connection.setRequestProperty("apikey", key)
                connection.setRequestProperty("Content-Type", "application/json")
                token?.let { connection.setRequestProperty("Authorization", "Bearer $it") }
                connection.doOutput = true
                connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
                val code = connection.responseCode
                val stream = if (code in 200..299) connection.inputStream else connection.errorStream
                val bytes = stream?.use { input ->
                    val buffer = java.io.ByteArrayOutputStream()
                    val chunk = ByteArray(8_192)
                    while (true) {
                        val count = input.read(chunk)
                        if (count < 0) break
                        if (buffer.size() + count > 16 * 1024 * 1024) throw CloudFailure("حجم بيانات المزامنة أكبر من الحد المتاح.")
                        buffer.write(chunk, 0, count)
                    }
                    buffer.toByteArray()
                } ?: byteArrayOf()
                val raw = bytes.toString(Charsets.UTF_8)
                val json = if (raw.isBlank()) JSONObject() else runCatching { JSONObject(raw) }.getOrElse {
                    throw CloudFailure("استجابة الخدمة غير صالحة. بياناتك المحلية محفوظة.")
                }
                if (code !in 200..299) {
                    val errorCode = json.optString("error_code", json.optString("code"))
                    val message = when {
                        errorCode == "email_not_confirmed" -> "أكّد بريدك الإلكتروني أولًا، ثم سجّل الدخول."
                        code == 400 && path.startsWith("/auth/v1/token") -> "البريد الإلكتروني أو كلمة المرور غير صحيحة، أو انتهت الجلسة."
                        code == 401 -> "انتهت الجلسة. سجّل الدخول مجددًا."
                        code == 429 -> "محاولات كثيرة. انتظر قليلًا ثم أعد المحاولة."
                        code == 403 -> "لم تسمح الخدمة بهذه العملية. بياناتك المحلية محفوظة."
                        errorCode == "PGRST202" -> "خدمة المزامنة تحتاج تحديثًا. بياناتك المحلية محفوظة."
                        else -> "تعذّر إتمام الطلب. بياناتك المحلية محفوظة؛ أعد المحاولة."
                    }
                    throw CloudFailure(message, code)
                }
                json
            } catch (failure: CloudFailure) {
                throw failure
            } catch (_: java.io.IOException) {
                throw CloudFailure("تعذّر الاتصال بالخدمة. تحقق من الإنترنت؛ بياناتك المحلية محفوظة.")
            } finally { connection.disconnect() }
        }
}
