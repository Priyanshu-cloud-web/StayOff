package com.focusguard

data class BlockRule(
    val packageName: String,
    val blockEntireApp: Boolean,
    val blockShorts: Boolean = false,
    val blockReels: Boolean = false
)