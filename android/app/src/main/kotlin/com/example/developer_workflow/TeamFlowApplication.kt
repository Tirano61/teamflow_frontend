package com.dramirez.teamflow

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Crea el canal de notificaciones antes de que Firebase Messaging lo use.
 *
 * FCM muestra las notificaciones de segundo plano en el canal declarado en
 * `default_notification_channel_id`; si ese canal no existe, usa
 * `fcm_fallback_notification_channel`. Cuando un push despierta la app en
 * frio, Android ejecuta `Application.onCreate` antes que el receptor de FCM,
 * por eso el canal se crea aqui y no desde Dart o desde la Activity.
 */
class TeamFlowApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createDiscussionsNotificationChannel()
    }

    private fun createDiscussionsNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        // Si el canal ya existe, Android solo actualiza nombre y descripcion:
        // la importancia y los ajustes elegidos por el usuario se conservan.
        val channel = NotificationChannel(
            getString(R.string.discussions_notification_channel_id),
            getString(R.string.discussions_notification_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = getString(R.string.discussions_notification_channel_description)
        }

        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }
}
