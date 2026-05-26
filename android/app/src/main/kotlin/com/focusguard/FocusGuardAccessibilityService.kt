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
        const val TAG = "FocusGuard"
        const val PREFS_NAME = "fg_block_prefs"
        const val CHANNEL_ID = "focusguard_blocks"

        const val KEY_BLOCK_SHORTS = "block_yt_shorts"
        const val KEY_ALWAYS_BLOCK_SHORTS = "always_block_yt_shorts"
        const val KEY_BLOCK_REELS = "block_ig_reels"
        const val KEY_ALWAYS_BLOCK_REELS = "always_block_ig_reels"
        const val KEY_BLOCK_TIKTOK = "block_tiktok"
        const val KEY_BLOCK_SNAP = "block_snap_spotlight"
        const val KEY_BLOCKED_PKGS = "blocked_app_pkgs"
        const val KEY_APP_BUDGETS = "blocked_app_budgets"
        const val KEY_DAILY_USAGE = "fg_daily_usage"
        const val KEY_LAST_RESET = "fg_last_reset"
        const val KEY_SITE_BUDGETS = "fg_site_budgets"

        private const val BLOCK_COOLDOWN = 800L
        private const val BLOCK_RESET_DELAY = 1000L
        private const val SESSION_SAVE_INTERVAL = 60000L
    }

    private lateinit var prefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private var notificationManager: NotificationManager? = null

    private var isBlocking = false
    private var lastBlockTime = 0L
    private var currentApp = ""
    
    private var isInShorts = false
    private var isInReels = false
    
    private var lastShortsBlockTime = 0L
    private var lastReelsBlockTime = 0L
    
    private val dailyUsage = mutableMapOf<String, Int>()
    private val activeSessions = mutableMapOf<String, Long>()
    
    private val blockedPackages = mutableSetOf<String>()
    private val appBudgets = mutableMapOf<String, Int>()

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        setupService()
        createNotificationChannel()
        loadAllData()
        checkDailyReset()
        startSessionSaver()
        
        val alwaysBlockShorts = prefs.getBoolean(KEY_ALWAYS_BLOCK_SHORTS, false)
        val shortsBudget = getShortsBudget()
        
        Log.d(TAG, "✅ Service connected")
        Log.d(TAG, "   Shorts blocking enabled: ${prefs.getBoolean(KEY_BLOCK_SHORTS, false)}")
        Log.d(TAG, "   Always block shorts: $alwaysBlockShorts")
        Log.d(TAG, "   Shorts budget: $shortsBudget minutes")
    }
    
    private fun setupService() {
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            
            notificationTimeout = 100
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "FocusGuard",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setSound(null, null)
                setShowBadge(false)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }
    
    private fun loadAllData() {
        val pkgsRaw = prefs.getString(KEY_BLOCKED_PKGS, "") ?: ""
        blockedPackages.clear()
        blockedPackages.addAll(pkgsRaw.split(",").filter { it.isNotEmpty() })
        
        val budgetsRaw = prefs.getString(KEY_APP_BUDGETS, "") ?: ""
        appBudgets.clear()
        budgetsRaw.split(",").forEach {
            val parts = it.split(":")
            if (parts.size == 2) {
                appBudgets[parts[0]] = parts[1].toIntOrNull() ?: 0
            }
        }
        
        val usageRaw = prefs.getString(KEY_DAILY_USAGE, "") ?: ""
        dailyUsage.clear()
        usageRaw.split(",").forEach {
            val parts = it.split(":")
            if (parts.size == 2) {
                dailyUsage[parts[0]] = parts[1].toIntOrNull() ?: 0
            }
        }
    }
    
    private fun checkDailyReset() {
        val today = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())
        val lastReset = prefs.getString(KEY_LAST_RESET, "")
        
        if (lastReset != today) {
            dailyUsage.clear()
            prefs.edit()
                .putString(KEY_LAST_RESET, today)
                .putString(KEY_DAILY_USAGE, "")
                .apply()
            Log.d(TAG, "🔄 Daily reset for $today")
        }
    }
    
    private fun saveDailyUsage() {
        val data = dailyUsage.entries.joinToString(",") { "${it.key}:${it.value}" }
        prefs.edit().putString(KEY_DAILY_USAGE, data).apply()
    }
    
    private fun addUsage(key: String, minutes: Int) {
        val current = dailyUsage[key] ?: 0
        val newTotal = current + minutes
        dailyUsage[key] = newTotal
        saveDailyUsage()
        Log.d(TAG, "📊 $key: +$minutes min (total: $newTotal min)")
    }
    
    private fun startSession(key: String, now: Long) {
        if (!activeSessions.containsKey(key)) {
            activeSessions[key] = now
            Log.d(TAG, "▶️ Started session: $key")
        }
    }
    
    private fun endSession(key: String, now: Long) {
        val startTime = activeSessions.remove(key) ?: return
        val durationMinutes = ((now - startTime) / 60000).toInt()
        
        if (durationMinutes > 0) {
            addUsage(key, durationMinutes)
            Log.d(TAG, "⏹️ Ended session: $key, duration: $durationMinutes min")
        }
    }
    
    private fun startSessionSaver() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                saveAllActiveSessions()
                handler.postDelayed(this, SESSION_SAVE_INTERVAL)
            }
        }, SESSION_SAVE_INTERVAL)
    }
    
    private fun saveAllActiveSessions() {
        val now = System.currentTimeMillis()
        activeSessions.keys.toList().forEach { key ->
            val startTime = activeSessions[key] ?: return@forEach
            val durationMinutes = ((now - startTime) / 60000).toInt()
            if (durationMinutes > 0) {
                addUsage(key, durationMinutes)
                activeSessions[key] = now
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        
        val packageName = event.packageName?.toString() ?: return
        val now = System.currentTimeMillis()
        
        if (packageName == "com.focusguard") return
        
        if (isBlocking && now - lastBlockTime < BLOCK_COOLDOWN) return
        
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            if (packageName != currentApp) {
                if (currentApp.isNotEmpty() && blockedPackages.contains(currentApp)) {
                    endSession(currentApp, now)
                }
                currentApp = packageName
                
                if (!packageName.contains("youtube") && !packageName.contains("instagram")) {
                    isInShorts = false
                    isInReels = false
                }
                
                checkFullAppBlock(packageName, now)
            }
        }
        
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            checkForShortsAndReels(packageName, now)
        }
    }
    
    private fun checkFullAppBlock(packageName: String, now: Long) {
        if ((packageName.contains("musically") || packageName.contains("ugc.trill")) &&
            prefs.getBoolean(KEY_BLOCK_TIKTOK, false)) {
            blockNow("TikTok is blocked", true)
            return
        }
        
        if (packageName.contains("snapchat") && prefs.getBoolean(KEY_BLOCK_SNAP, false)) {
            blockNow("Snapchat is blocked", true)
            return
        }
        
        if (!blockedPackages.contains(packageName)) return
        
        val budgetMinutes = appBudgets[packageName] ?: 0
        val usedToday = dailyUsage[packageName] ?: 0
        
        if (budgetMinutes == 0) {
            blockNow("${getAppName(packageName)} is blocked", true)
        } else if (usedToday >= budgetMinutes) {
            blockNow("${getAppName(packageName)}: Daily limit of $budgetMinutes min reached", true)
        } else {
            startSession(packageName, now)
            val remaining = budgetMinutes - usedToday
            if (remaining <= 5 && remaining > 0) {
                showNotification("${getAppName(packageName)}: $remaining min left today")
            }
        }
    }
    
    private fun checkForShortsAndReels(packageName: String, now: Long) {
        val root = rootInActiveWindow ?: return
        
        when (packageName) {
            "com.google.android.youtube" -> {
                val blockShorts = prefs.getBoolean(KEY_BLOCK_SHORTS, false)
                if (blockShorts) {
                    handleYouTubeShorts(root, now)
                }
            }
            "com.instagram.android" -> {
                val blockReels = prefs.getBoolean(KEY_BLOCK_REELS, false)
                if (blockReels) {
                    handleInstagramReels(root, now)
                }
            }
        }
    }
    
    private fun handleYouTubeShorts(root: AccessibilityNodeInfo, now: Long) {
        if (now - lastShortsBlockTime < BLOCK_RESET_DELAY) {
            return
        }
        
        var foundShorts = false
        
        val shortsPlayerIds = listOf(
            "com.google.android.youtube:id/reel_player_page_container",
            "com.google.android.youtube:id/shorts_player_container",
            "com.google.android.youtube:id/reel_video_container"
        )
        
        for (id in shortsPlayerIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes.isNotEmpty() && nodes[0].isVisibleToUser) {
                    foundShorts = true
                    Log.d(TAG, "🎯 Shorts detected by view ID")
                    break
                }
            } catch (e: Exception) { }
        }
        
        if (!foundShorts) {
            try {
                val likeButton = root.findAccessibilityNodeInfosByText("Like")
                val commentButton = root.findAccessibilityNodeInfosByText("Comment")
                val shareButton = root.findAccessibilityNodeInfosByText("Share")
                
                if (likeButton.isNotEmpty() && commentButton.isNotEmpty() && shareButton.isNotEmpty()) {
                    foundShorts = true
                    Log.d(TAG, "🎯 Shorts detected by button layout")
                }
            } catch (e: Exception) { }
        }
        
        if (foundShorts) {
            val shortsKey = "youtube/shorts"  // ← MATCH the key used in writeSiteBudgets
            val alwaysBlock = prefs.getBoolean(KEY_ALWAYS_BLOCK_SHORTS, false)
            val budgetMinutes = getShortsBudget()
            val usedToday = dailyUsage[shortsKey] ?: 0
            
            Log.d(TAG, "📊 Shorts - AlwaysBlock: $alwaysBlock, Budget: $budgetMinutes, Used: $usedToday")
            
            isInShorts = true
            
            var shouldBlock = false
            var blockReason = ""
            
            if (alwaysBlock) {
                shouldBlock = true
                blockReason = "YouTube Shorts are blocked (Always Block)"
            } else if (budgetMinutes <= 0) {
                shouldBlock = true
                blockReason = "YouTube Shorts are blocked (No budget set)"
            } else if (usedToday >= budgetMinutes) {
                shouldBlock = true
                blockReason = "YouTube Shorts limit reached ($usedToday/$budgetMinutes min)"
            }
            
            if (shouldBlock) {
                blockShortsContent(blockReason, shortsKey, now)
            } else {
                startSession(shortsKey, now)
                val remaining = budgetMinutes - usedToday
                if (remaining <= 5) {
                    showNotification("YouTube Shorts: $remaining min left today")
                }
                Log.d(TAG, "✅ Shorts within budget: $usedToday/$budgetMinutes min, tracking time")
            }
        } else {
            if (isInShorts) {
                isInShorts = false
                endSession("youtube/shorts", now)
                Log.d(TAG, "✅ Exited Shorts")
            }
        }
    }
    
    private fun handleInstagramReels(root: AccessibilityNodeInfo, now: Long) {
        if (now - lastReelsBlockTime < BLOCK_RESET_DELAY) {
            return
        }
        
        var foundReels = false
        
        val reelsPlayerIds = listOf(
            "com.instagram.android:id/clips_viewer_pager"
        )
        
        for (id in reelsPlayerIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes.isNotEmpty() && nodes[0].isVisibleToUser) {
                    foundReels = true
                    Log.d(TAG, "🎯 Reels detected")
                    break
                }
            } catch (e: Exception) { }
        }
        
        if (foundReels) {
            val reelsKey = "instagram/reels"
            val alwaysBlock = prefs.getBoolean(KEY_ALWAYS_BLOCK_REELS, false)
            val budgetMinutes = getReelsBudget()
            val usedToday = dailyUsage[reelsKey] ?: 0
            
            Log.d(TAG, "📊 Reels - AlwaysBlock: $alwaysBlock, Budget: $budgetMinutes, Used: $usedToday")
            
            isInReels = true
            
            var shouldBlock = false
            var blockReason = ""
            
            if (alwaysBlock) {
                shouldBlock = true
                blockReason = "Instagram Reels are blocked"
            } else if (budgetMinutes <= 0) {
                shouldBlock = true
                blockReason = "Instagram Reels are blocked (No budget set)"
            } else if (usedToday >= budgetMinutes) {
                shouldBlock = true
                blockReason = "Instagram Reels limit reached ($usedToday/$budgetMinutes min)"
            }
            
            if (shouldBlock) {
                blockShortsContent(blockReason, reelsKey, now)
            } else {
                startSession(reelsKey, now)
                Log.d(TAG, "✅ Reels within budget: $usedToday/$budgetMinutes min")
            }
        } else {
            if (isInReels) {
                isInReels = false
                endSession("instagram/reels", now)
                Log.d(TAG, "✅ Exited Reels")
            }
        }
    }
    
    private fun getShortsBudget(): Int {
        val siteBudgets = prefs.getString(KEY_SITE_BUDGETS, "") ?: ""
        Log.d(TAG, "Site budgets raw: $siteBudgets")
        
        // Try both formats
        siteBudgets.split(",").forEach {
            val parts = it.split(":")
            if (parts.size == 2) {
                val key = parts[0]
                val value = parts[1].toIntOrNull() ?: 0
                if (key == "youtube/shorts" || key == "youtube.com/shorts") {
                    Log.d(TAG, "Found budget for $key: $value")
                    return value
                }
            }
        }
        return 0
    }
    
    private fun getReelsBudget(): Int {
        val siteBudgets = prefs.getString(KEY_SITE_BUDGETS, "") ?: ""
        siteBudgets.split(",").forEach {
            val parts = it.split(":")
            if (parts.size == 2 && (parts[0] == "instagram/reels" || parts[0] == "instagram.com/reels")) {
                return parts[1].toIntOrNull() ?: 0
            }
        }
        return 0
    }
    
    private fun blockShortsContent(contentName: String, trackingKey: String, now: Long) {
        if (isBlocking) return
        
        Log.d(TAG, "🚫 BLOCKING: $contentName")
        
        isBlocking = true
        lastBlockTime = now
        
        if (contentName.contains("Shorts")) {
            lastShortsBlockTime = now
        } else if (contentName.contains("Reels")) {
            lastReelsBlockTime = now
        }
        
        endSession(trackingKey, now)
        performGlobalAction(GLOBAL_ACTION_BACK)
        showNotification(contentName)
        
        handler.postDelayed({
            isBlocking = false
        }, BLOCK_COOLDOWN)
        
        handler.postDelayed({
            if (contentName.contains("Shorts")) {
                isInShorts = false
            } else if (contentName.contains("Reels")) {
                isInReels = false
            }
        }, 500)
    }
    
    private fun blockNow(message: String, goHome: Boolean) {
        if (isBlocking) return
        
        isBlocking = true
        lastBlockTime = System.currentTimeMillis()
        
        if (goHome) {
            performGlobalAction(GLOBAL_ACTION_HOME)
        } else {
            performGlobalAction(GLOBAL_ACTION_BACK)
        }
        
        showNotification(message)
        
        handler.postDelayed({
            isBlocking = false
        }, BLOCK_COOLDOWN)
        
        Log.d(TAG, "🚫 $message")
    }
    
    private fun showNotification(message: String) {
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("FocusGuard")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_LOW)
            .build()
        notificationManager?.notify(message.hashCode(), notification)
    }
    
    private fun getAppName(packageName: String): String {
        return when {
            packageName.contains("instagram") -> "Instagram"
            packageName.contains("youtube") -> "YouTube"
            packageName.contains("facebook") -> "Facebook"
            packageName.contains("tiktok") -> "TikTok"
            packageName.contains("snapchat") -> "Snapchat"
            else -> packageName.substringAfterLast(".")
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }
    
    override fun onDestroy() {
        val now = System.currentTimeMillis()
        activeSessions.keys.toList().forEach { key ->
            endSession(key, now)
        }
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}