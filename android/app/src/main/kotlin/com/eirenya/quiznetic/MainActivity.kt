package com.eirenya.quiznetic

import android.app.Activity
import android.app.Application
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

class MainActivity : FlutterActivity() {
    private lateinit var adsRecoveryChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerActivityTrackerIfNeeded()
    }

    override fun onDestroy() {
        unregisterActivityTrackerIfNeeded()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        adsRecoveryChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ADS_RECOVERY_CHANNEL,
        )
        adsRecoveryChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "finishStuckAdActivity" -> {
                    val currentActivity = currentActivityRef.get()
                    val activityClass = currentActivity?.javaClass?.name
                    val finished =
                        if (activityClass == AD_ACTIVITY_CLASS_NAME) {
                            currentActivity.runOnUiThread {
                                currentActivity.finish()
                            }
                            true
                        } else {
                            false
                        }
                    result.success(
                        mapOf(
                            "finished" to finished,
                            "activityClass" to activityClass,
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        adsRecoveryChannel.setMethodCallHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun registerActivityTrackerIfNeeded() {
        if (activityTrackerRegistered) {
            return
        }
        application.registerActivityLifecycleCallbacks(activityTracker)
        activityTrackerRegistered = true
    }

    private fun unregisterActivityTrackerIfNeeded() {
        if (!activityTrackerRegistered) {
            return
        }
        application.unregisterActivityLifecycleCallbacks(activityTracker)
        activityTrackerRegistered = false
    }

    companion object {
        private const val ADS_RECOVERY_CHANNEL = "com.eirenya.quiznetic/ads_recovery"
        private const val AD_ACTIVITY_CLASS_NAME = "com.google.android.gms.ads.AdActivity"
        private var activityTrackerRegistered = false
        private var currentActivityRef: WeakReference<Activity> = WeakReference(null)

        private val activityTracker =
            object : Application.ActivityLifecycleCallbacks {
                override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) =
                    Unit

                override fun onActivityStarted(activity: Activity) = Unit

                override fun onActivityResumed(activity: Activity) {
                    currentActivityRef = WeakReference(activity)
                }

                override fun onActivityPaused(activity: Activity) {
                    if (currentActivityRef.get() === activity) {
                        currentActivityRef = WeakReference(null)
                    }
                }

                override fun onActivityStopped(activity: Activity) = Unit

                override fun onActivitySaveInstanceState(
                    activity: Activity,
                    outState: Bundle,
                ) = Unit

                override fun onActivityDestroyed(activity: Activity) {
                    if (currentActivityRef.get() === activity) {
                        currentActivityRef = WeakReference(null)
                    }
                }
            }
    }
}
