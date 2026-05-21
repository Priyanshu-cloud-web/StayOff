package com.focusguard

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.text.SimpleDateFormat
import java.util.*

class FocusGuardAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "FocusGuardA11y"
        const val PREFS_NAME = "fg_block_prefs"
        const val CHANNEL_ID = "fg_blocks"

        const val KEY_BLOCK_SHORTS = "block_yt_shorts"
        const val KEY_ALWAYS_BLOCK_SHORTS = "always_block_yt_shorts"

        const val KEY_BLOCK_REELS = "block_ig_reels"
        const val KEY_ALWAYS_BLOCK_REELS = "always_block_ig_reels"

        const val KEY_BLOCK_TIKTOK = "block_tiktok"
        const val KEY_BLOCK_SNAP = "block_snap_spotlight"

        const val KEY_BLOCKED_PKGS = "blocked_app_pkgs"
        const val KEY_APP_BUDGETS = "blocked_app_budgets"
        const val KEY_APP_USED_MS = "blocked_app_used_ms"

        private const val BLOCK_COOLDOWN_MS = 1800L
        private const val SCAN_THROTTLE_MS = 400L

        const val KEY_YT_SHORTS = "youtube.com/shorts"
        const val KEY_IG_REELS = "instagram.com/reels"

        private val YT_SHORTS_IDS = listOf(
            "com.google.android.youtube:id/reel_player_page_container",
            "com.google.android.youtube:id/shorts_container",
            "com.google.android.youtube:id/shorts_player_container"
        )

        private val IG_REELS_IDS = listOf(
            "com.instagram.android:id/clips_viewer_pager",
            "com.instagram.android:id/reels_tray_container"
        )
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences
    private var nm: NotificationManager? = null

    @Volatile private var isBlocking = false
    @Volatile private var lastBlockMs = 0L
    @Volatile private var lastScanMs = 0L

    private val openedAt = mutableMapOf<String, Long>()
    private val usedTodayMs = mutableMapOf<String, Long>()

    // ─────────────────────────────

    override fun onServiceConnected() {
        super.onServiceConnected()

        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        nm = getSystemService(NotificationManager::class.java)

        createChannel()
        loadUsage()

        serviceInfo = serviceInfo.apply {
            eventTypes =
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_SCROLLED

            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 50

            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS

            packageNames = null
        }

        Log.d(TAG, "✅ Service connected")
    }

    // ─────────────────────────────

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return

        val pkg = event.packageName?.toString() ?: return
        val now = System.currentTimeMillis()

        if (pkg == "com.focusguard") return
        if (isBlocking) return
        if (now - lastBlockMs < BLOCK_COOLDOWN_MS) return

        val blockedPkgs = (prefs.getString(KEY_BLOCKED_PKGS, "") ?: "")
            .split(",").map { it.trim() }.filter { it.isNotEmpty() }

        if (pkg in blockedPkgs) {
            if (!isAppWithinBudget(pkg, now)) {
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
            return
        }

        if (pkg.contains("musically") || pkg.contains("ugc.trill")) {
            if (prefs.getBoolean(KEY_BLOCK_TIKTOK, false)) {
                block("TikTok blocked", true)
            }
            return
        }

        if (now - lastScanMs < SCAN_THROTTLE_MS) return
        lastScanMs = now

        val root = rootInActiveWindow ?: return

        when (pkg) {

            "com.google.android.youtube" -> {

                if (!prefs.getBoolean(KEY_BLOCK_SHORTS, false)) {
                    openedAt.remove(KEY_YT_SHORTS)
                    return
                }

                val isShorts = isYouTubeShorts(root)

                // ✅ ALWAYS BLOCK MODE
                if (prefs.getBoolean(KEY_ALWAYS_BLOCK_SHORTS, false)) {
                    if (isShorts) block("YouTube Shorts blocked", false)
                    return
                }

                // ✅ TIME BASED MODE
                if (isShorts) {

                    if (!openedAt.containsKey(KEY_YT_SHORTS)) {
                        openedAt[KEY_YT_SHORTS] = now
                    }

                    if (!isShortsWithinBudget(KEY_YT_SHORTS, now)) {
                        block("YouTube Shorts blocked", false)
                    }

                } else {
                    commitSession(KEY_YT_SHORTS, now)
                }
            }

            "com.instagram.android" -> {

                if (!prefs.getBoolean(KEY_BLOCK_REELS, false)) {
                    openedAt.remove(KEY_IG_REELS)
                    return
                }

                val isReels = hasViewId(root, IG_REELS_IDS)

                if (prefs.getBoolean(KEY_ALWAYS_BLOCK_REELS, false)) {
                    if (isReels) block("Instagram Reels blocked", false)
                    return
                }

                if (isReels) {

                    if (!openedAt.containsKey(KEY_IG_REELS)) {
                        openedAt[KEY_IG_REELS] = now
                    }

                    if (!isShortsWithinBudget(KEY_IG_REELS, now)) {
                        block("Instagram Reels blocked", false)
                    }

                } else {
                    commitSession(KEY_IG_REELS, now)
                }
            }

            "com.facebook.katana" -> {

                val blockFbReels =
                    prefs.getBoolean("block_fb_reels", false)

                if (!blockFbReels) return

                val reelTexts = listOf(
                    "Reels",
                    "Suggested reels",
                    "Watch more reels"
                )

                val isReel = reelTexts.any {
                    root.findAccessibilityNodeInfosByText(it).isNotEmpty()
                }

                if (isReel) {
                    block("Facebook Reels blocked", false)
                }
            }

            "com.android.chrome" -> {

                val blockBrowserShorts =
                    prefs.getBoolean("block_browser_shorts", false)

                if (!blockBrowserShorts) return

                val blockedTexts = listOf(
                    "shorts",
                    "reels"
                )

                val detected = blockedTexts.any {
                    root.findAccessibilityNodeInfosByText(it).isNotEmpty()
                }

                if (detected) {
                    block("Blocked in browser", false)
                }
            }
        }
    }

    // ─────────────────────────────
    // DETECTION
    // ─────────────────────────────

    private fun isYouTubeShorts(root: AccessibilityNodeInfo): Boolean {
        return hasViewId(root, YT_SHORTS_IDS)
    }

    private fun hasViewId(root: AccessibilityNodeInfo, ids: List<String>): Boolean {
        for (id in ids) {
            try {
                if (root.findAccessibilityNodeInfosByViewId(id).isNotEmpty()) {
                    return true
                }
            } catch (_: Exception) {}
        }
        return false
    }

    // ─────────────────────────────

    private fun block(msg: String, exitApp: Boolean) {
        val now = System.currentTimeMillis()
        if (isBlocking) return

        isBlocking = true
        lastBlockMs = now

        listOf(KEY_YT_SHORTS, KEY_IG_REELS).forEach {
            if (openedAt.containsKey(it)) commitSession(it, now)
        }

        if (exitApp) performGlobalAction(GLOBAL_ACTION_HOME)
        else performGlobalAction(GLOBAL_ACTION_BACK)

        handler.postDelayed({ isBlocking = false }, BLOCK_COOLDOWN_MS)

        showNotification(msg)
    }

    // ─────────────────────────────
    // BUDGET
    // ─────────────────────────────

    private fun isShortsWithinBudget(key: String, now: Long): Boolean {
        val budget = getSiteBudgetMinutes(key)

        // ✅ FIX: allow if no time set
        if (budget <= 0) return true

        val used = totalUsedMs(key, now) / 60000
        return used < budget
    }

    private fun getSiteBudgetMinutes(key: String): Int {
        val raw = prefs.getString("fg_site_budgets", "") ?: return 0
        raw.split(",").forEach {
            if (it.startsWith("$key:")) {
                return it.split(":")[1].toIntOrNull() ?: 0
            }
        }
        return 0
    }

    private fun totalUsedMs(key: String, now: Long): Long {
        val saved = usedTodayMs[key] ?: 0L
        val session = openedAt[key]?.let { now - it } ?: 0L
        return saved + session
    }

    private fun commitSession(key: String, now: Long) {
        val start = openedAt.remove(key) ?: return
        val session = now - start
        if (session > 0) {
            usedTodayMs[key] = (usedTodayMs[key] ?: 0) + session
            saveUsage()
        }
    }

    private fun isAppWithinBudget(pkg: String, now: Long): Boolean {
        val raw = prefs.getString(KEY_APP_BUDGETS, "") ?: return false
        var budget = 0
        raw.split(",").forEach {
            if (it.startsWith("$pkg:")) {
                budget = it.split(":")[1].toIntOrNull() ?: 0
            }
        }
        if (budget <= 0) return false
        val used = totalUsedMs(pkg, now) / 60000
        return used < budget
    }

    private fun loadUsage() {
        val today = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())
        val stored = prefs.getString("fg_usage_date", "")

        if (stored != today) {
            prefs.edit().putString("fg_usage_date", today)
                .remove(KEY_APP_USED_MS).apply()
            usedTodayMs.clear()
        } else {
            val raw = prefs.getString(KEY_APP_USED_MS, "") ?: ""
            raw.split(",").forEach {
                val parts = it.split(":")
                if (parts.size == 2) {
                    usedTodayMs[parts[0]] = parts[1].toLongOrNull() ?: 0
                }
            }
        }
    }

    private fun saveUsage() {
        val data = usedTodayMs.entries.joinToString(",") {
            "${it.key}:${it.value}"
        }
        prefs.edit().putString(KEY_APP_USED_MS, data).apply()
    }

    // ─────────────────────────────

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm?.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "StayOff Blocks",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }
    }

    private fun showNotification(msg: String) {
        val builder = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("StayOff")
            .setContentText(msg)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setAutoCancel(true)

        nm?.notify(1001, builder.build())
    }

    override fun onInterrupt() {}
}