package com.icexsilent.stream_deck;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.view.View;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetLaunchIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

/** Home screen widget: up to 6 buttons of the page chosen in Configurações. Data comes from lib/home_widget_sync.dart. */
public class DeckWidgetProvider extends HomeWidgetProvider {
  private static final int[] SLOTS = {R.id.slot0, R.id.slot1, R.id.slot2, R.id.slot3, R.id.slot4, R.id.slot5};

  @Override
  public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, SharedPreferences widgetData) {
    for (int widgetId : appWidgetIds) {
      RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.deck_widget);
      int count = widgetData.getInt("count", 0);
      // The helpers are Kotlin objects without @JvmStatic, hence INSTANCE and the explicit null uri.
      PendingIntent openApp = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, null);
      String page = widgetData.getString("page", null);
      views.setTextViewText(R.id.title, page != null ? "Stream Deck · " + page : "Stream Deck");
      views.setOnClickPendingIntent(R.id.title, openApp);
      views.setViewVisibility(R.id.empty, count == 0 ? View.VISIBLE : View.GONE);
      views.setOnClickPendingIntent(R.id.empty, openApp);
      views.setViewVisibility(R.id.row0, count > 0 ? View.VISIBLE : View.GONE);
      views.setViewVisibility(R.id.row1, count > 3 ? View.VISIBLE : View.GONE);
      for (int i = 0; i < SLOTS.length; i++) {
        if (i < count) {
          views.setViewVisibility(SLOTS[i], View.VISIBLE);
          views.setTextViewText(SLOTS[i], widgetData.getString("label_" + i, ""));
          // Each slot gets its own URI, so Android keeps a separate PendingIntent per button.
          Uri uri = Uri.parse("streamdeck://press?id=" + Uri.encode(widgetData.getString("id_" + i, "")));
          views.setOnClickPendingIntent(SLOTS[i], HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, uri));
        } else {
          // Keeps the grid aligned on a half-filled row.
          views.setViewVisibility(SLOTS[i], View.INVISIBLE);
        }
      }
      appWidgetManager.updateAppWidget(widgetId, views);
    }
  }
}
