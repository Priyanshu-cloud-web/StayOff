package com.example.focusguard_app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class MyAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString()

        Log.d("FocusGuard", "App opened: $packageName")
    }

    override fun onInterrupt() {
        Log.d("FocusGuard", "Service Interrupted")
    }
}