package com.hoque.familychores

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget provider for Chores Star.
 *
 * Reads the same payload the Flutter app writes via [HomeWidgetBridge] and
 * renders a calm, small widget with a greeting, today's missions and a
 * pending-approval badge.
 */
class ChoresStarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val greeting = widgetData.getString("greeting", null) ?: "Hi there!"
        val streakDays = widgetData.getInt("currentStreakDays", 0)
        // "".split("\n") is [""] in Kotlin, not [] — without dropping blanks the
        // no-missions case rendered a bare "• " instead of the empty-state copy.
        // Swift's split(separator:) omits empty subsequences, so iOS never had
        // this and the two widgets disagreed on the same payload.
        val missionTitles = widgetData.getString("missionTitles", "")
            ?.split("\n")
            ?.filter { it.isNotBlank() }
            ?: emptyList()
        val pendingApprovalCount = widgetData.getInt("pendingApprovalCount", 0)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.chores_star_widget).apply {
                // Tapping the widget opens the app.
                val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, launchIntent)

                setTextViewText(R.id.widget_greeting, greeting)

                if (pendingApprovalCount > 0) {
                    setTextViewText(R.id.widget_badge, pendingApprovalCount.toString())
                    setViewVisibility(R.id.widget_badge, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_badge, android.view.View.GONE)
                }

                if (missionTitles.isEmpty()) {
                    setTextViewText(R.id.widget_missions, "No missions today 🎉")
                } else {
                    val text = missionTitles.take(MAX_MISSIONS).joinToString("\n") { "• $it" }
                    setTextViewText(R.id.widget_missions, text)
                }

                if (streakDays > 0) {
                    setTextViewText(R.id.widget_streak, "🔥 ${streakDays}-day streak")
                    setViewVisibility(R.id.widget_streak, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_streak, android.view.View.GONE)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        private const val MAX_MISSIONS = 3
    }
}
