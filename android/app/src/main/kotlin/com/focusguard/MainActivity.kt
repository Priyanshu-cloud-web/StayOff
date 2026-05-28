package com.focusguard

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val VPN_CHANNEL = "com.focusguard/vpn"
        const val APP_CHANNEL = "com.focusguard/app_blocker"
        const val VPN_REQ = 1001
        const val PREFS_NAME = "fg_block_prefs"
        
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
    }

    private var pendingVpnResult: MethodChannel.Result? = null
    private var pendingVpnUrls: List<String> = emptyList()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // VPN CHANNEL
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VPN_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "updateBlocklist" -> {
                    val urls = call.argument<List<String>>("urls") ?: emptyList()
                    Log.d("MainActivity", "updateBlocklist called with: $urls")
                    
                    val enableShorts = urls.any { url ->
                        url.lowercase().contains("youtube.com/shorts") ||
                        url.lowercase().contains("youtube/shorts") ||
                        (url.lowercase().contains("shorts") && url.lowercase().contains("youtube"))
                    }
                    
                    val alwaysBlock = call.argument<Boolean>("alwaysBlock") ?: false
                    
                    getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean(KEY_BLOCK_SHORTS, enableShorts)
                        .putBoolean(KEY_ALWAYS_BLOCK_SHORTS, alwaysBlock)
                        .apply()
                    
                    Log.d("MainActivity", "✅ Shorts blocking set to: $enableShorts (Always: $alwaysBlock)")
                    result.success(true)
                }
                
                "startVpn" -> {
                    result.success(true)
                }
                
                "stopVpn" -> {
                    result.success(true)
                }
                
                "writeSiteBudgets" -> {
                    val budgets = call.argument<String>("budgets") ?: ""
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    
                    // If budget is set for Shorts with value > 0, ensure timer mode
                    if (budgets.contains("youtube.com/shorts:") || budgets.contains("youtube/shorts:")) {
                        val parts = budgets.split(",")
                        for (part in parts) {
                            if (part.startsWith("youtube.com/shorts:") || part.startsWith("youtube/shorts:")) {
                                val budgetValue = part.split(":")[1].toIntOrNull() ?: 0
                                if (budgetValue > 0) {
                                    prefs.edit().putBoolean(KEY_ALWAYS_BLOCK_SHORTS, false).apply()
                                    Log.d("MainActivity", "Timer mode enabled for Shorts (budget: $budgetValue min)")
                                }
                                break
                            }
                        }
                    }
                    
                    prefs.edit().putString(KEY_SITE_BUDGETS, budgets).apply()
                    result.success(true)
                }
                
                "readSiteUsage" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val usedMs = prefs.getString(KEY_DAILY_USAGE, "") ?: ""
                    val siteBudgets = prefs.getString(KEY_SITE_BUDGETS, "") ?: ""
                    result.success(mapOf("usedMs" to usedMs, "siteBudgets" to siteBudgets))
                }
                
                else -> result.notImplemented()
            }
        }

        // APP CHANNEL - Handles app blocking
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "checkAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                
                "addBlockedApp" -> {
                    val pkg = call.argument<String>("packageName") ?: return@setMethodCallHandler
                    val budget = call.argument<Int>("budgetMinutes") ?: 0
                    addBlockedApp(pkg, budget)
                    Log.d("MainActivity", "✅ Added blocked app: $pkg with budget: $budget min")
                    result.success(true)
                }
                
                "removeBlockedApp" -> {
                    val pkg = call.argument<String>("packageName") ?: return@setMethodCallHandler
                    removeBlockedApp(pkg)
                    Log.d("MainActivity", "✅ Removed blocked app: $pkg")
                    result.success(true)
                }
                
                "getBlockedApps" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val blockedPkgs = prefs.getString(KEY_BLOCKED_PKGS, "") ?: ""
                    val budgets = prefs.getString(KEY_APP_BUDGETS, "") ?: ""
                    val usage = prefs.getString(KEY_DAILY_USAGE, "") ?: ""
                    result.success(mapOf(
                        "blocked" to blockedPkgs,
                        "budgets" to budgets,
                        "usage" to usage
                    ))
                }
                
                "getAllUsage" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val usageRaw = prefs.getString(KEY_DAILY_USAGE, "") ?: ""
                    val usageMap = mutableMapOf<String, Int>()
                    
                    usageRaw.split(",").forEach {
                        val parts = it.split(":")
                        if (parts.size == 2) {
                            usageMap[parts[0]] = parts[1].toIntOrNull() ?: 0
                        }
                    }
                    result.success(usageMap)
                }
                
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName
        }
    }

    private fun openAccessibilitySettings() {
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun addBlockedApp(packageName: String, budgetMinutes: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        // Add to blocked packages list
        val currentBlocked = prefs.getString(KEY_BLOCKED_PKGS, "") ?: ""
        val blockedSet = if (currentBlocked.isNotEmpty()) {
            currentBlocked.split(",").filter { it.isNotEmpty() }.toMutableSet()
        } else {
            mutableSetOf()
        }
        blockedSet.add(packageName)
        prefs.edit().putString(KEY_BLOCKED_PKGS, blockedSet.joinToString(",")).apply()
        
        // Add to budgets
        val currentBudgets = prefs.getString(KEY_APP_BUDGETS, "") ?: ""
        val budgetMap = mutableMapOf<String, Int>()
        if (currentBudgets.isNotEmpty()) {
            currentBudgets.split(",").forEach {
                val parts = it.split(":")
                if (parts.size == 2) {
                    budgetMap[parts[0]] = parts[1].toIntOrNull() ?: 0
                }
            }
        }
        budgetMap[packageName] = budgetMinutes
        prefs.edit().putString(KEY_APP_BUDGETS, budgetMap.entries.joinToString(",") { "${it.key}:${it.value}" }).apply()
    }

    private fun removeBlockedApp(packageName: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        // Remove from blocked packages list
        val currentBlocked = prefs.getString(KEY_BLOCKED_PKGS, "") ?: ""
        val blockedSet = if (currentBlocked.isNotEmpty()) {
            currentBlocked.split(",").filter { it.isNotEmpty() }.toMutableSet()
        } else {
            mutableSetOf()
        }
        blockedSet.remove(packageName)
        prefs.edit().putString(KEY_BLOCKED_PKGS, blockedSet.joinToString(",")).apply()
        
        // Remove from budgets
        val currentBudgets = prefs.getString(KEY_APP_BUDGETS, "") ?: ""
        val budgetMap = mutableMapOf<String, Int>()
        if (currentBudgets.isNotEmpty()) {
            currentBudgets.split(",").forEach {
                val parts = it.split(":")
                if (parts.size == 2 && parts[0] != packageName) {
                    budgetMap[parts[0]] = parts[1].toIntOrNull() ?: 0
                }
            }
        }
        prefs.edit().putString(KEY_APP_BUDGETS, budgetMap.entries.joinToString(",") { "${it.key}:${it.value}" }).apply()
    }
}