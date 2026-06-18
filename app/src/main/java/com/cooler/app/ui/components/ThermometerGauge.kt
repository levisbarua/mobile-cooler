package com.cooler.app.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cooler.app.ui.theme.CoolCyan
import com.cooler.app.ui.theme.HotRed
import com.cooler.app.ui.theme.WarmOrange
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.PI

@Composable
fun ThermometerGauge(
    temperature: Float,
    modifier: Modifier = Modifier,
    size: Dp = 220.dp,
) {
    val sweepAngle by animateFloatAsState(
        targetValue = (temperature.coerceIn(15f, 55f) - 15f) / 40f * 270f,
        animationSpec = tween(durationMillis = 600),
        label = "sweep",
    )

    val gaugeColor = when {
        temperature >= 50f -> HotRed
        temperature >= 45f -> MaterialTheme.colorScheme.error
        temperature >= 40f -> WarmOrange
        else -> CoolCyan
    }

    Box(
        modifier = modifier.size(size),
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.fillMaxSize().padding(12.dp)) {
            val strokeWidth = 24f
            val radius = (size.minus(24.dp).toPx() / 2) - strokeWidth / 2
            val center = Offset(size.toPx() / 2, size.toPx() / 2)

            drawArc(
                color = Color.DarkGray.copy(alpha = 0.3f),
                startAngle = 135f,
                sweepAngle = 270f,
                useCenter = false,
                style = androidx.compose.ui.graphics.drawscope.Stroke(strokeWidth, cap = StrokeCap.Round),
                topLeft = Offset(center.x - radius, center.y - radius),
                size = androidx.compose.ui.geometry.Size(radius * 2, radius * 2),
            )

            drawArc(
                color = gaugeColor,
                startAngle = 135f,
                sweepAngle = sweepAngle,
                useCenter = false,
                style = androidx.compose.ui.graphics.drawscope.Stroke(strokeWidth, cap = StrokeCap.Round),
                topLeft = Offset(center.x - radius, center.y - radius),
                size = androidx.compose.ui.geometry.Size(radius * 2, radius * 2),
            )

            val needleAngle = 135f + sweepAngle
            val needleRad = needleAngle * PI / 180f
            val needleLength = radius - strokeWidth / 2 - 8f
            val needleEnd = Offset(
                center.x + needleLength * cos(needleRad).toFloat(),
                center.y + needleLength * sin(needleRad).toFloat(),
            )
            drawLine(
                color = gaugeColor,
                start = center,
                end = needleEnd,
                strokeWidth = 4f,
                cap = StrokeCap.Round,
            )
            drawCircle(
                color = gaugeColor,
                radius = 10f,
                center = center,
            )
        }

        Text(
            text = "${temperature.toInt()}°",
            style = MaterialTheme.typography.displayLarge.copy(
                fontSize = 48.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground,
            ),
        )
    }
}
