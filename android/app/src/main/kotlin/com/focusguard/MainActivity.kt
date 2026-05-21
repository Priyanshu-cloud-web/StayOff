package com.focusguard

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val VPN_CHANNEL  = "com.focusguard/vpn"
        const val APP_CHANNEL  = "com.focusguard/app_blocker"
        const val VPN_REQ      = 1001

        const val PREFS_NAME       = "fg_block_prefs"
        const val KEY_BLOCK_SHORTS = "block_yt_shorts"
        const val KEY_BLOCK_REELS  = "block_ig_reels"
        const val KEY_BLOCK_TIKTOK = "block_tiktok"
        const val KEY_BLOCK_SNAP   = "block_snap_spotlight"
        const val KEY_BLOCKED_PKGS   = "blocked_app_pkgs"
        const val KEY_APP_BUDGETS    = "blocked_app_budgets"  // "pkg1:60,pkg2:0" format

        val userBlocklist  = mutableSetOf<String>()
        val adultBlocklist = mutableSetOf<String>()
    }

    private var pendingVpnResult: MethodChannel.Result? = null
    private var pendingVpnUrls:   List<String>          = emptyList()

    override fun configureFlutterEngine(fe: FlutterEngine) {
        super.configureFlutterEngine(fe)

        // ── VPN CHANNEL ──────────────────────────────────────────────
        MethodChannel(fe.dartExecutor.binaryMessenger, VPN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startVpn" -> {
                        val urls = call.argument<List<String>>("urls") ?: emptyList()
                        // startVpn is called by SafeGuard with adult domains only
                        // Do NOT call writeBlockPrefs here — that would overwrite the
                        // block_yt_shorts flag set by the user's blocklist.
                        // A11y prefs are managed exclusively by updateBlocklist.
                        userBlocklist.clear()
                        userBlocklist.addAll(urls.map { it.lowercase() }.filter { !it.contains("/") })
                        requestVpnThenStart(mergedUrls(), result)
                    }

                    "stopVpn" -> { stopVpn(); result.success(true) }

                    "updateBlocklist" -> {
                        val urls  = call.argument<List<String>>("urls") ?: emptyList()
                        val lower = urls.map { it.lowercase() }

                        if (lower.size >= 20) {
                            // SafeGuard adult domain list (30-40 entries)
                            adultBlocklist.clear()
                            adultBlocklist.addAll(lower)
                        } else {
                            // User's manual blocklist
                            // Rules for what goes to VPN:
                            // 1. Must contain a dot (real domain like canva.com, not just "canva")
                            // 2. Must NOT contain "/" (path-based like youtube.com/shorts → A11y only)
                            val domainOnly = lower.filter { url ->
                                url.contains(".") && !url.contains("/")
                            }
                            userBlocklist.clear()
                            userBlocklist.addAll(domainOnly)
                            writeBlockPrefs(lower)  // sets block_yt_shorts etc.
                            android.util.Log.d("FocusGuard", "VPN domains: $domainOnly from $lower")
                        }

                        val merged = mergedUrls()
                        if (merged.isEmpty()) { stopVpn(); result.success(true); return@setMethodCallHandler }

                        val vpnIntent = VpnService.prepare(this)
                        if (vpnIntent != null) {
                            pendingVpnResult = result
                            pendingVpnUrls   = merged
                            @Suppress("DEPRECATION")
                            startActivityForResult(vpnIntent, VPN_REQ)
                        } else {
                            startVpn(merged)
                            result.success(true)
                        }
                    }

                    "writeSiteBudgets" -> {
                        val budgets = call.argument<String>("budgets") ?: ""
                        // Store so A11y service can read time limits for path-based URLs
                        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            .edit().putString("fg_site_budgets", budgets).apply()
                        result.success(true)
                    }
                    "readSiteUsage" -> {
                        // Returns "url:msUsed,url2:msUsed2" from A11y SharedPrefs
                        val prefs = getSharedPreferences(
                            "fg_block_prefs", Context.MODE_PRIVATE)
                        val usedMs    = prefs.getString("blocked_app_used_ms", "") ?: ""
                        val siteBudgets = prefs.getString("fg_site_budgets", "") ?: ""
                        result.success(mapOf("usedMs" to usedMs, "siteBudgets" to siteBudgets))
                    }
                    "isVpnRunning" ->
                        result.success(FocusGuardVpnService.blockedDomains.isNotEmpty())

                    else -> result.notImplemented()
                }
            }

        // ── APP BLOCKER CHANNEL ──────────────────────────────────────
        MethodChannel(fe.dartExecutor.binaryMessenger, APP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkUsagePermission"         -> result.success(false)
                    "checkAccessibilityPermission" -> result.success(isA11yEnabled())
                    "openAccessibilitySettings"    -> { openA11yDirect(); result.success(true) }
                    "openUsageSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    }
                    "addBlockedApp" -> {
                        val pkg     = call.argument<String>("packageName") ?: return@setMethodCallHandler
                        val budget  = call.argument<Int>("budgetMinutes") ?: 0
                        addPkg(pkg)
                        setBudget(pkg, budget)
                        result.success(true)
                    }
                    "removeBlockedApp" -> {
                        val pkg = call.argument<String>("packageName") ?: return@setMethodCallHandler
                        removePkg(pkg); result.success(true)
                    }
                    "updateBudget" -> {
                        val pkg    = call.argument<String>("packageName") ?: return@setMethodCallHandler
                        val budget = call.argument<Int>("budgetMinutes") ?: 0
                        setBudget(pkg, budget)
                        result.success(true)
                    }
                    "toggleApp" -> {
                        val pkg = call.argument<String>("packageName") ?: return@setMethodCallHandler
                        togglePkg(pkg); result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── VPN PERMISSION ────────────────────────────────────────────────
    private fun requestVpnThenStart(urls: List<String>, result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            pendingVpnResult = result
            pendingVpnUrls   = urls
            @Suppress("DEPRECATION")
            startActivityForResult(intent, VPN_REQ)
        } else {
            startVpn(urls)
            result.success(true)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(req: Int, res: Int, data: Intent?) {
        super.onActivityResult(req, res, data)
        if (req == VPN_REQ) {
            if (res == Activity.RESULT_OK) {
                startVpn(pendingVpnUrls.ifEmpty { mergedUrls() })
                pendingVpnResult?.success(true)
            } else {
                pendingVpnResult?.error("VPN_DENIED", "VPN permission denied", null)
            }
            pendingVpnResult = null
            pendingVpnUrls   = emptyList()
        }
    }

    // ── VPN HELPERS ───────────────────────────────────────────────────
    private fun mergedUrls() = (userBlocklist + adultBlocklist).toList()

    private fun startVpn(urls: List<String>) {
        FocusGuardVpnService.blockedDomains.clear()
        FocusGuardVpnService.blockedDomains.addAll(urls)
        startForegroundService(Intent(this, FocusGuardVpnService::class.java).apply {
            action = FocusGuardVpnService.ACTION_START
            putStringArrayListExtra(FocusGuardVpnService.EXTRA_URLS, ArrayList(urls))
        })
    }

    private fun stopVpn() {
        FocusGuardVpnService.blockedDomains.clear()
        startService(Intent(this, FocusGuardVpnService::class.java).apply {
            action = FocusGuardVpnService.ACTION_STOP
        })
    }

    // ── SHARED PREFS FOR ACCESSIBILITY SERVICE ────────────────────────
    // These flags are read by FocusGuardAccessibilityService in its own process
    private fun writeBlockPrefs(urls: List<String>) {
        // Write A11y blocking flags based on what's in the USER blocklist.
        // Called only from updateBlocklist (never from startVpn/SafeGuard).
        val lower = urls.map { it.lowercase() }
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putBoolean(KEY_BLOCK_SHORTS, lower.any { it.contains("youtube") || it.contains("shorts") })
            putBoolean(KEY_BLOCK_REELS,  lower.any { it.contains("instagram") || it.contains("reels") })
            putBoolean(KEY_BLOCK_TIKTOK, lower.any { it.contains("tiktok") })
            putBoolean(KEY_BLOCK_SNAP,   lower.any { it.contains("snapchat") })
        }.apply()
        android.util.Log.d("FocusGuardMain", "A11y prefs written: shorts=${lower.any { it.contains("youtube") || it.contains("shorts") }}")
    }

    // ── APP BUDGET ───────────────────────────────────────────────────────
    private fun setBudget(pkg: String, minutes: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_APP_BUDGETS, "") ?: ""
        val map = parseBudgets(raw).toMutableMap()
        map[pkg] = minutes
        prefs.edit().putString(KEY_APP_BUDGETS, map.entries.joinToString(",") { "${it.key}:${it.value}" }).apply()
    }

    private fun parseBudgets(raw: String): Map<String, Int> {
        if (raw.isEmpty()) return emptyMap()
        return raw.split(",").mapNotNull {
            val parts = it.trim().split(":")
            if (parts.size == 2) parts[0] to (parts[1].toIntOrNull() ?: 0) else null
        }.toMap()
    }

    // ── ACCESSIBILITY ─────────────────────────────────────────────────
    private fun openA11yDirect() {
        // Try to deep-link directly to FocusGuard's own accessibility entry
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                val comp = "$packageName/.FocusGuardAccessibilityService"
                startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra(":settings:fragment_args_key", comp)
                    val b = Bundle(); b.putString(":settings:fragment_args_key", comp)
                    putExtra(":settings:show_fragment_args", b)
                })
                return
            } catch (_: Exception) {}
        }
        // Fallback: general accessibility settings list
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }

    private fun isA11yEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        return am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.resolveInfo.serviceInfo.packageName == packageName }
    }

    // ── BLOCKED APP PACKAGES (persisted in SharedPreferences) ─────────
    private fun getPkgs(): MutableSet<String> {
        val raw = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_BLOCKED_PKGS, "") ?: ""
        return if (raw.isEmpty()) mutableSetOf()
               else raw.split(",").map { it.trim() }.filter { it.isNotEmpty() }.toMutableSet()
    }
    private fun savePkgs(s: Set<String>) =
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putString(KEY_BLOCKED_PKGS, s.joinToString(",")).apply()
    private fun addPkg(p: String)    { val s = getPkgs(); s.add(p);    savePkgs(s) }
    private fun removePkg(p: String) { val s = getPkgs(); s.remove(p); savePkgs(s) }
    private fun togglePkg(p: String) { val s = getPkgs(); if (p in s) s.remove(p) else s.add(p); savePkgs(s) }

    // Push a11y status to Flutter every time app resumes
    override fun onResume() {
        super.onResume()
        flutterEngine?.dartExecutor?.binaryMessenger?.let { m ->
            MethodChannel(m, APP_CHANNEL).invokeMethod("_notifyA11yStatus", isA11yEnabled())
        }
    }
}