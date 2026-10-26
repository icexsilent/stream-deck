package com.icexsilent.stream_deck

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Home screen widget: up to 6 buttons of the page chosen in Configurações. Data comes from lib/home_widget_sync.dart. */
class DeckWidgetProvider : HomeWidgetProvider() {
  private val slots = intArrayOf(R.id.slot0, R.id.slot1, R.id.slot2, R.id.slot3, R.id.slot4, R.id.slot5)

  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.deck_widget)
      val count = widgetData.getInt("count", 0)
      val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
      views.setTextViewText(R.id.title, widgetData.getString("page", null)?.let { "Stream Deck · $it" } ?: "Stream Deck")
      views.setOnClickPendingIntent(R.id.title, openApp)
      views.setViewVisibility(R.id.empty, if (count == 0) View.VISIBLE else View.GONE)
      views.setOnClickPendingIntent(R.id.empty, openApp)
      views.setViewVisibility(R.id.row0, if (count > 0) View.VISIBLE else View.GONE)
      views.setViewVisibility(R.id.row1, if (count > 3) View.VISIBLE else View.GONE)
      slots.forEachIndexed { i, slot ->
        if (i < count) {
          views.setViewVisibility(slot, View.VISIBLE)
          views.setTextViewText(slot, widgetData.getString("label_$i", ""))
          // Each slot gets its own URI, so Android keeps a separate PendingIntent per button.
          val uri = Uri.parse("streamdeck://press?id=" + Uri.encode(widgetData.getString("id_$i", "")))
          views.setOnClickPendingIntent(slot, HomeWidgetBackgroundIntent.getBroadcast(context, uri))
        } else {
          // Keeps the grid aligned on a half-filled row.
          views.setViewVisibility(slot, View.INVISIBLE)
        }
      }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
