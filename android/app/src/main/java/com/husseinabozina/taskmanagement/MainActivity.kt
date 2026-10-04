package com.husseinabozina.taskmanagement

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.husseinabozina.taskmanagement.ui.theme.TaskManagementTheme

/**
 * نقطة دخول نسخة أندرويد — مسار D1 المرحلة A0.
 * الهيكل والعقود مشتركة مع iOS وفق docs/architecture/DATA_CONTRACTS.md.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TaskManagementTheme {
                HomeStubScreen()
            }
        }
    }
}

/// حالة انتقالية صادقة لمسار A0 — لا أزرار ولا بيانات وهمية.
@Composable
private fun HomeStubScreen() {
    Scaffold(containerColor = MaterialTheme.colorScheme.background) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(146.dp)
                    .padding(horizontal = 22.dp, vertical = 12.dp)
                    .background(Color(0xFF5F33E1), RoundedCornerShape(24.dp)),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        "مهامي — أندرويد",
                        color = Color.White,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        "المسار بدأ: A0 هيكل المشروع — الطبقات جاية وفق نفس العقود",
                        color = Color.White.copy(alpha = 0.85f),
                        fontSize = 13.sp
                    )
                }
            }
            Text(
                "نفس عقود المنتج من docs/architecture/DATA_CONTRACTS.md ستُنفذ هنا: المهام، المشاريع، التذكيرات، والمزامنة عبر Supabase.",
                modifier = Modifier.padding(22.dp),
                fontSize = 14.sp,
                color = Color(0xFF6E6A7C)
            )
        }
    }
}
