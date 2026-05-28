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
    private var currentForegroundApp = ""
    
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
        
        setupAccessibilityConfig()
        createNotificationChannel()
        loadAllData()
        checkDailyReset()
        startSessionSaver()
        
        Log.d(TAG, "✅ Service connected")
        Log.d(TAG, "   Blocked apps: $blockedPackages")
        Log.d(TAG, "   App budgets: $appBudgets")
        Log.d(TAG, "   Shorts blocking: ${prefs.getBoolean(KEY_BLOCK_SHORTS, false)}")
        Log.d(TAG, "   Always block shorts: ${prefs.getBoolean(KEY_ALWAYS_BLOCK_SHORTS, false)}")
        Log.d(TAG, "   Shorts budget: ${getShortsBudget()}")
    }
    
    private fun setupAccessibilityConfig() {
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            
            notificationTimeout = 50
            packageNames = null
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
        if (pkgsRaw.isNotEmpty()) {
            blockedPackages.addAll(pkgsRaw.split(",").filter { it.isNotEmpty() })
        }
        
        val budgetsRaw = prefs.getString(KEY_APP_BUDGETS, "") ?: ""
        appBudgets.clear()
        if (budgetsRaw.isNotEmpty()) {
            budgetsRaw.split(",").forEach {
                val parts = it.split(":")
                if (parts.size == 2) {
                    appBudgets[parts[0]] = parts[1].toIntOrNull() ?: 0
                }
            }
        }
        
        val usageRaw = prefs.getString(KEY_DAILY_USAGE, "") ?: ""
        dailyUsage.clear()
        if (usageRaw.isNotEmpty()) {
            usageRaw.split(",").forEach {
                val parts = it.split(":")
                if (parts.size == 2) {
                    dailyUsage[parts[0]] = parts[1].toIntOrNull() ?: 0
                }
            }
        }
        
        Log.d(TAG, "📊 Loaded ${blockedPackages.size} blocked apps")
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
            Log.d(TAG, "⏹️ Ended session: $key, +$durationMinutes min")
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
            Log.d(TAG, "📱 App opened: $packageName")
            
            if (packageName != currentForegroundApp) {
                if (currentForegroundApp.isNotEmpty() && blockedPackages.contains(currentForegroundApp)) {
                    endSession(currentForegroundApp, now)
                }
                
                currentForegroundApp = packageName
                
                if (!packageName.contains("youtube") && !packageName.contains("instagram")) {
                    isInShorts = false
                    isInReels = false
                }
                
                checkAndBlockApp(packageName, now)
            }
        }
        
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            handleSpecialContent(packageName)
        }
    }
    
    // ==================== APP BLOCKING ====================
    
    private fun checkAndBlockApp(packageName: String, now: Long) {
        if (!blockedPackages.contains(packageName)) {
            return
        }
        
        val budgetMinutes = appBudgets[packageName] ?: 0
        val usedToday = dailyUsage[packageName] ?: 0
        
        Log.d(TAG, "🔍 App: $packageName - Budget: $budgetMinutes, Used: $usedToday")
        
        when {
            budgetMinutes == 0 -> {
                Log.d(TAG, "🚫 Always block: $packageName")
                blockFullApp(getAppDisplayName(packageName), packageName, now)
            }
            usedToday >= budgetMinutes -> {
                Log.d(TAG, "🚫 Time limit exceeded: $packageName")
                blockFullApp(getAppDisplayName(packageName), packageName, now)
            }
            else -> {
                startSession(packageName, now)
                val remaining = budgetMinutes - usedToday
                if (remaining <= 5) {
                    showNotification("${getAppDisplayName(packageName)}: $remaining min left")
                }
                Log.d(TAG, "✅ $packageName within budget")
            }
        }
    }
    
    private fun blockFullApp(appName: String, packageName: String, now: Long) {
        if (isBlocking) return
        
        Log.d(TAG, "🚫 BLOCKING APP: $appName")
        
        isBlocking = true
        lastBlockTime = now
        
        endSession(packageName, now)
        performGlobalAction(GLOBAL_ACTION_HOME)
        showNotification("$appName is blocked")
        
        handler.postDelayed({ isBlocking = false }, BLOCK_COOLDOWN)
    }
    
    // ==================== SHORTS/REELS BLOCKING ====================
    
    private fun handleSpecialContent(packageName: String) {
        val root = rootInActiveWindow ?: return
        
        when (packageName) {
            "com.google.android.youtube" -> {
                if (prefs.getBoolean(KEY_BLOCK_SHORTS, false)) {
                    detectAndBlockYouTubeShorts(root)
                }
            }
            "com.instagram.android" -> {
                if (prefs.getBoolean(KEY_BLOCK_REELS, false)) {
                    detectAndBlockInstagramReels(root)
                }
            }
        }
    }
    
    private fun detectAndBlockYouTubeShorts(root: AccessibilityNodeInfo) {
        val now = System.currentTimeMillis()
        if (now - lastShortsBlockTime < BLOCK_RESET_DELAY) return
        
        var foundShorts = false
        
        val shortsViewIds = listOf(
            "com.google.android.youtube:id/reel_player_page_container",
            "com.google.android.youtube:id/shorts_container",
            "com.google.android.youtube:id/shorts_player_container"
        )
        
        for (id in shortsViewIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes.isNotEmpty() && nodes[0].isVisibleToUser) {
                    foundShorts = true
                    break
                }
            } catch (e: Exception) { }
        }
        
        if (foundShorts) {
            // ✅ FIXED: Use the same key that is saved (youtube/shorts)
            val shortsKey = "youtube/shorts"
            val alwaysBlock = prefs.getBoolean(KEY_ALWAYS_BLOCK_SHORTS, false)
            val budgetMinutes = getShortsBudget()
            val usedToday = dailyUsage[shortsKey] ?: 0
            
            Log.d(TAG, "📊 Shorts - Budget: $budgetMinutes, Used: $usedToday, AlwaysBlock: $alwaysBlock")
            
            if (alwaysBlock) {
                blockShortsContent("YouTube Shorts are blocked", shortsKey, now)
            } else if (budgetMinutes <= 0) {
                blockShortsContent("YouTube Shorts are blocked (no budget)", shortsKey, now)
            } else if (usedToday >= budgetMinutes) {
                blockShortsContent("YouTube Shorts limit reached ($usedToday/$budgetMinutes min)", shortsKey, now)
            } else {
                if (!isInShorts) {
                    isInShorts = true
                    startSession(shortsKey, now)
                    Log.d(TAG, "✅ Shorts within budget, tracking ($usedToday/$budgetMinutes min)")
                }
            }
        } else {
            if (isInShorts) {
                isInShorts = false
                endSession("youtube/shorts", System.currentTimeMillis())
                Log.d(TAG, "✅ Exited Shorts")
            }
        }
    }
    
    private fun detectAndBlockInstagramReels(root: AccessibilityNodeInfo) {
        val now = System.currentTimeMillis()
        if (now - lastReelsBlockTime < BLOCK_RESET_DELAY) return
        
        var foundReels = false
        
        val reelsViewIds = listOf(
            "com.instagram.android:id/clips_viewer_pager",
            "com.instagram.android:id/reels_tray_container"
        )
        
        for (id in reelsViewIds) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes.isNotEmpty() && nodes[0].isVisibleToUser) {
                    foundReels = true
                    break
                }
            } catch (e: Exception) { }
        }
        
        if (foundReels) {
            // ✅ FIXED: Use the same key format
            val reelsKey = "instagram/reels"
            val alwaysBlock = prefs.getBoolean(KEY_ALWAYS_BLOCK_REELS, false)
            val budgetMinutes = getReelsBudget()
            val usedToday = dailyUsage[reelsKey] ?: 0
            
            Log.d(TAG, "📊 Reels - Budget: $budgetMinutes, Used: $usedToday")
            
            if (alwaysBlock) {
                blockShortsContent("Instagram Reels are blocked", reelsKey, now)
            } else if (budgetMinutes <= 0) {
                blockShortsContent("Instagram Reels are blocked (no budget)", reelsKey, now)
            } else if (usedToday >= budgetMinutes) {
                blockShortsContent("Instagram Reels limit reached", reelsKey, now)
            } else {
                if (!isInReels) {
                    isInReels = true
                    startSession(reelsKey, now)
                    Log.d(TAG, "✅ Reels within budget")
                }
            }
        } else {
            if (isInReels) {
                isInReels = false
                endSession("instagram/reels", System.currentTimeMillis())
                Log.d(TAG, "✅ Exited Reels")
            }
        }
    }
    
    private fun getShortsBudget(): Int {
        val siteBudgets = prefs.getString(KEY_SITE_BUDGETS, "") ?: ""
        Log.d(TAG, "Site budgets raw: $siteBudgets")
        siteBudgets.split(",").forEach {
            val parts = it.split(":")
            if (parts.size == 2) {
                val key = parts[0]
                val value = parts[1].toIntOrNull() ?: 0
                // ✅ FIXED: Check both formats
                if (key == "youtube/shorts" || key == "youtube.com/shorts") {
                    Log.d(TAG, "Found budget: $key = $value")
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
            if (parts.size == 2) {
                val key = parts[0]
                val value = parts[1].toIntOrNull() ?: 0
                if (key == "instagram/reels" || key == "instagram.com/reels") {
                    return value
                }
            }
        }
        return 0
    }
    
    private fun blockShortsContent(contentName: String, trackingKey: String, now: Long) {
        if (isBlocking) return
        
        Log.d(TAG, "🚫 BLOCKING CONTENT: $contentName")
        
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
        
        handler.postDelayed({ isBlocking = false }, BLOCK_COOLDOWN)
        
        handler.postDelayed({
            if (contentName.contains("Shorts")) isInShorts = false
            if (contentName.contains("Reels")) isInReels = false
        }, 500)
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
    
    private fun getAppDisplayName(packageName: String): String {
        return when {
            packageName.contains("instagram") -> "Instagram"
            packageName.contains("youtube") -> "YouTube"
            packageName.contains("facebook") -> "Facebook"
            packageName.contains("tiktok") -> "TikTok"
            packageName.contains("snapchat") -> "Snapchat"
            packageName.contains("whatsapp") -> "WhatsApp"
            else -> packageName.substringAfterLast(".")
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }
    
    override fun onDestroy() {
        val now = System.currentTimeMillis()
        activeSessions.keys.toList().forEach { endSession(it, now) }
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}