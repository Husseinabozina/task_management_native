package com.husseinabozina.taskmanagement.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.husseinabozina.taskmanagement.cloud.CloudController
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountSheet(cloud: CloudController, onDismiss: () -> Unit) {
    val state by cloud.state.collectAsStateWithLifecycle()
    var register by rememberSaveable { mutableStateOf(false) }
    var email by rememberSaveable { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    LaunchedEffect(state.email) { if (state.email != null) password = "" }
    ModalBottomSheet(onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = MaterialTheme.colorScheme.background) {
        Column(Modifier.fillMaxWidth().imePadding().verticalScroll(rememberScrollState()).padding(horizontal = 22.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)) {
            SectionHeading("الحساب والمزامنة") {
                TextButton(onClick = onDismiss) { Text("إغلاق") }
            }
            if (!state.configured) {
                EmptyState("المزامنة غير مهيّأة في هذه النسخة", "يمكنك الاستمرار في تنظيم مهامك وحفظها محليًا.")
            } else if (state.email == null) {
                Text("الحساب اختياري. سجّل الدخول لمزامنة مهامك بين أجهزتك؛ يمكنك استخدام التطبيق محليًا دون حساب.")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    ChoiceChip("دخول", !register, !state.busy) { register = false; cloud.clearMessages() }
                    ChoiceChip("حساب جديد", register, !state.busy) { register = true; cloud.clearMessages() }
                }
                OutlinedTextField(email, { email = it }, Modifier.fillMaxWidth(), enabled = !state.busy,
                    label = { Text("البريد الإلكتروني") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.None,
                        autoCorrectEnabled = false, keyboardType = KeyboardType.Email))
                OutlinedTextField(password, { password = it }, Modifier.fillMaxWidth(), enabled = !state.busy,
                    label = { Text("كلمة المرور") }, singleLine = true, visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password))
                PrimaryAction(if (state.busy) "يرجى الانتظار…" else if (register) "إنشاء الحساب" else "تسجيل الدخول", !state.busy) {
                    if (register) cloud.signUp(email, password) else cloud.signIn(email, password)
                }
            } else {
                AppCard {
                    Text(state.email!!)
                    Spacer(Modifier.height(8.dp))
                    val last = state.lastSyncAt
                    if (last == null) Text("لم تُجرَ مزامنة بعد.", color = MaterialTheme.colorScheme.secondary)
                    else {
                        val formatter = DateTimeFormatter.ofPattern("d MMM yyyy، h:mm a", Arabic).withZone(ZoneId.systemDefault())
                        Text("آخر مزامنة: ${formatter.format(last)}", color = MaterialTheme.colorScheme.secondary)
                    }
                }
                Text("تُحفظ نسخة احتياطية محلية قبل أول مزامنة. اضغط «مزامنة الآن» على كل جهاز لتبادل أحدث المهام والمشاريع.")
                PrimaryAction(if (state.busy) "جارٍ التنفيذ…" else "مزامنة الآن", !state.busy, cloud::syncNow)
                TextButton(enabled = !state.busy, onClick = cloud::signOut, modifier = Modifier.fillMaxWidth()) {
                    Text("تسجيل الخروج", color = MaterialTheme.colorScheme.error)
                }
            }
            state.error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            state.notice?.let { Text(it, color = MaterialTheme.colorScheme.primary) }
            Spacer(Modifier.height(28.dp))
        }
    }
}
