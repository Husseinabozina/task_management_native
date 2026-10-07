package com.husseinabozina.taskmanagement.cloud

import android.content.Context
import android.util.AtomicFile
import com.husseinabozina.taskmanagement.data.AppDatabase
import com.husseinabozina.taskmanagement.reminders.ReminderScheduler
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONObject
import java.io.File
import java.time.Instant

data class CloudState(val configured: Boolean, val busy: Boolean = true, val email: String? = null,
    val lastSyncAt: Instant? = null, val error: String? = null, val notice: String? = null)

class CloudController(context: Context, private val scope: CoroutineScope) {
    private val context = context.applicationContext
    private val api = CloudApi()
    private val vault = SessionVault(this.context)
    private val store = CloudStore(AppDatabase.get(this.context))
    private val metadata = context.getSharedPreferences("cloud_metadata", 0)
    private val mutable = MutableStateFlow(CloudState(api.configured))
    val state = mutable.asStateFlow()
    private var session: CloudSession? = null

    fun clearMessages() {
        if (!mutable.value.busy) mutable.value = mutable.value.copy(error = null, notice = null)
    }

    init {
        scope.launch {
            try {
                session = withContext(Dispatchers.IO) { vault.read() }
                val last = metadata.getString("lastSyncAt", null)?.let { runCatching { Instant.parse(it) }.getOrNull() }
                mutable.value = mutable.value.copy(email = session?.email, lastSyncAt = last)
            } catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { mutable.value = mutable.value.copy(error = "تعذّر استعادة الجلسة. سجّل الدخول مجددًا؛ مهامك محفوظة.") }
            finally { mutable.value = mutable.value.copy(busy = false) }
        }
    }

    fun signIn(email: String, password: String) = operation {
        requireCredentials(email, password)
        accept(CloudSession.fromAuth(api.request("/auth/v1/token?grant_type=password",
            JSONObject().put("email", email.trim()).put("password", password))))
    }

    fun signUp(email: String, password: String) = operation {
        requireCredentials(email, password)
        if (password.length < 6) throw CloudFailure("استخدم كلمة مرور من 6 أحرف على الأقل.")
        val response = api.request("/auth/v1/signup", JSONObject().put("email", email.trim()).put("password", password))
        if (response.has("access_token") && !response.isNull("access_token")) accept(CloudSession.fromAuth(response))
        else mutable.value = mutable.value.copy(notice = "إذا كان البريد صالحًا للتسجيل، ستصلك رسالة تأكيد. أكّد بريدك ثم سجّل الدخول.")
    }

    fun signOut() = operation {
        val current = session
        try { current?.let { api.request("/auth/v1/logout?scope=local", token = it.accessToken) } }
        catch (cancelled: CancellationException) { throw cancelled }
        catch (_: Exception) { /* Local sign-out is still possible offline. */ }
        withContext(Dispatchers.IO) { vault.clear() }
        session = null
        mutable.value = mutable.value.copy(email = null, notice = "تم تسجيل الخروج من هذا الجهاز. مهامك المحلية محفوظة.")
    }

    fun syncNow() = operation {
        val current = validSession()
        withContext(Dispatchers.IO) {
            val binding = metadata.getString("boundUserId", null)
            if (binding != null && binding != current.userId) throw CloudFailure(
                "بيانات هذا الجهاز مرتبطة بحساب آخر. سجّل الدخول بالحساب السابق لمزامنتها؛ لم تتغير مهامك.")
        }
        val snapshot = store.export()
        withContext(Dispatchers.IO) { backupAndBind(current.userId, snapshot) }
        val response = api.request("/rest/v1/rpc/sync_personal", snapshot, current.accessToken)
        store.apply(response, current.userId)
        val now = Instant.now()
        withContext(Dispatchers.IO) {
            check(metadata.edit().putString("lastSyncAt", now.toString()).commit())
        }
        mutable.value = mutable.value.copy(lastSyncAt = now, notice = "تمت المزامنة وحفظ بياناتك محليًا.")
        try { ReminderScheduler.reconcile(context) }
        catch (cancelled: CancellationException) { throw cancelled }
        catch (_: Exception) { mutable.value = mutable.value.copy(notice = "تمت المزامنة، لكن تعذّر تحديث التذكيرات. أعد فتح التطبيق للمحاولة.") }
    }

    private suspend fun accept(value: CloudSession) {
        withContext(Dispatchers.IO) { vault.save(value) }
        session = value
        val last = if (metadata.getString("boundUserId", null) == value.userId) mutable.value.lastSyncAt else null
        mutable.value = mutable.value.copy(email = value.email, lastSyncAt = last)
    }

    private suspend fun validSession(): CloudSession {
        val current = session ?: throw CloudFailure("سجّل الدخول أولًا.")
        if (current.expiresAt > System.currentTimeMillis() + 60_000) return current
        try {
            val renewed = CloudSession.fromAuth(api.request("/auth/v1/token?grant_type=refresh_token",
                JSONObject().put("refresh_token", current.refreshToken)))
            if (renewed.userId != current.userId) throw CloudFailure("تعذّر التحقق من الحساب. سجّل الدخول مجددًا.")
            accept(renewed)
            return renewed
        } catch (failure: CloudFailure) {
            if (failure.status == 400 || failure.status == 401) {
                withContext(Dispatchers.IO) { vault.clear() }
                session = null
                mutable.value = mutable.value.copy(email = null)
            }
            throw failure
        }
    }

    private fun backupAndBind(userId: String, snapshot: JSONObject) {
        val directory = File(context.filesDir, "Backups")
        check(directory.isDirectory || directory.mkdirs())
        val backup = AtomicFile(File(directory, "pre-sync-$userId.json"))
        if (!backup.baseFile.isFile || backup.baseFile.length() == 0L) {
            val output = backup.startWrite()
            try {
                val json = JSONObject().put("format", 1).put("ownerId", userId)
                    .put("createdAt", Instant.now()).put("data", snapshot)
                output.write(json.toString().toByteArray(Charsets.UTF_8))
                backup.finishWrite(output)
            } catch (failure: Exception) { backup.failWrite(output); throw failure }
        }
        check(metadata.edit().putString("boundUserId", userId).commit())
    }

    private fun requireCredentials(email: String, password: String) {
        if (email.isBlank() || password.isEmpty()) throw CloudFailure("البريد الإلكتروني وكلمة المرور مطلوبان.")
    }

    private fun operation(block: suspend () -> Unit) {
        if (mutable.value.busy) return
        mutable.value = mutable.value.copy(busy = true, error = null, notice = null)
        scope.launch {
            try { block() }
            catch (cancelled: CancellationException) { throw cancelled }
            catch (failure: CloudFailure) { mutable.value = mutable.value.copy(error = failure.readable) }
            catch (_: Exception) { mutable.value = mutable.value.copy(error = "تعذّر إتمام العملية. مهامك المحلية محفوظة؛ أعد المحاولة.") }
            finally { mutable.value = mutable.value.copy(busy = false) }
        }
    }
}
