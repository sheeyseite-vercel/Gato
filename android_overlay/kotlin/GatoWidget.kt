package com.gato.gato

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class GatoWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.gato_widget)
            views.setOnClickPendingIntent(R.id.btn_write, pending(context, "gato://new/entry", 1))
            views.setOnClickPendingIntent(R.id.btn_voice, pending(context, "gato://new/voice", 2))
            views.setOnClickPendingIntent(R.id.btn_quote, pending(context, "gato://new/quote", 3))
            manager.updateAppWidget(id, views)
        }
    }

    private fun pending(context: Context, uri: String, code: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            setPackage(context.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return PendingIntent.getActivity(
            context, code, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
