package com.focusguard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicBoolean

class FocusGuardVpnService : VpnService() {

    companion object {
        const val TAG        = "FocusGuardVPN"
        const val CHANNEL_ID = "focusguard_vpn"
        const val NOTIF_ID   = 1001
        const val ACTION_START = "com.focusguard.START_VPN"
        const val ACTION_STOP  = "com.focusguard.STOP_VPN"
        const val EXTRA_URLS   = "blocked_urls"

        private const val DNS_SERVER  = "8.8.8.8"
        private const val DNS_TIMEOUT = 3000

        val blockedDomains = mutableSetOf<String>()

        private val DOH_BLOCK = setOf(
            "dns.google", "cloudflare-dns.com", "one.one.one.one",
            "mozilla.cloudflare-dns.com", "dns.quad9.net"
        )
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private val running = AtomicBoolean(false)
    private var thread: Thread? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopVpn()
                return START_NOT_STICKY
            }
            else -> {
                intent?.getStringArrayListExtra(EXTRA_URLS)?.let { urls ->
                    blockedDomains.clear()
                    blockedDomains.addAll(urls.map { normalize(it) })
                    Log.d(TAG, "Blocking ${blockedDomains.size} domains")
                }
                if (blockedDomains.isEmpty()) {
                    Log.d(TAG, "No domains to block — stopping VPN to save battery")
                    stopVpn()
                    return START_NOT_STICKY
                }
                if (!running.get()) startVpn()
            }
        }
        return START_STICKY
    }

    private fun startVpn() {
        running.set(true)
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())
        try {
            val builder = Builder()
                .addAddress("10.0.0.2", 32)
                .addDnsServer("8.8.8.8")
                .addRoute("0.0.0.0", 0)
                .setMtu(1500)
                .setSession("StayOff")

            // Exclude payment/banking apps so they bypass the VPN entirely
            // and never show "VPN detected" warnings
            val excludedApps = listOf(
                "com.phonepe.app", "net.one97.paytm",
                "com.google.android.apps.nbu.paisa.user",
                "in.amazon.mShop.android.shopping",
                "com.mobikwik_new", "com.freecharge.android",
                "com.sbi.lotusintouch", "com.axis.mobile",
                "com.icici.iMobile", "com.csam.icici.bank.imobile",
                "com.hdfc.omni", "com.msf.kbank.mobile",
                "com.indus.omni", "com.pnb.mobilebanking",
                "com.coindcx.trade", "com.coinswitch.kuber",
                "com.amazon.mShop.android.shopping",
                "com.whatsapp"
            )
            for (app in excludedApps) {
                try { builder.addDisallowedApplication(app) } catch (_: Exception) {}
            }
            vpnInterface = builder.establish()
            thread = Thread({ runVpnLoop() }, "FG-VPN")
            thread?.start()
            Log.d(TAG, "VPN started")
        } catch (e: Exception) {
            Log.e(TAG, "VPN start failed: $e")
            running.set(false)
            stopForeground(STOP_FOREGROUND_REMOVE)
        }
    }

    private fun stopVpn() {
        running.set(false)
        thread?.interrupt()
        thread = null
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d(TAG, "VPN stopped")
    }

    private fun runVpnLoop() {
        val input  = FileInputStream(vpnInterface!!.fileDescriptor)
        val output = FileOutputStream(vpnInterface!!.fileDescriptor)
        val buffer = ByteArray(32767)

        while (running.get() && !Thread.interrupted()) {
            val len = try { input.read(buffer) } catch (_: Exception) { break }
            if (len < 1) {
                Thread.sleep(5)   // yield CPU briefly when no packets
                continue
            }
            if (len < 20) continue
            if (buffer[0].toInt() and 0xF0 ushr 4 != 4) continue
            val ihl   = (buffer[0].toInt() and 0x0F) * 4
            val proto = buffer[9].toInt() and 0xFF
            if (proto != 17 || len < ihl + 8) continue
            val dstPort = ((buffer[ihl + 2].toInt() and 0xFF) shl 8) or
                          (buffer[ihl + 3].toInt() and 0xFF)
            if (dstPort != 53) continue

            val dnsQuery = buffer.copyOfRange(ihl + 8, len)
            val domain   = parseDomain(dnsQuery)
            Log.d(TAG, "DNS -> $domain")

            if (domain != null && shouldBlock(domain)) {
                Log.w(TAG, "BLOCKED: $domain")
                val resp = buildReply(buffer, buildNxDomain(dnsQuery), ihl)
                if (resp != null) {
                    try { output.write(resp) } catch (_: Exception) {}
                }
            } else {
                val upstream = forwardDns(dnsQuery)
                if (upstream != null) {
                    val resp = buildReply(buffer, upstream, ihl)
                    if (resp != null) {
                        try { output.write(resp) } catch (_: Exception) {}
                    }
                }
            }
        }
        Log.d(TAG, "VPN loop ended")
    }

    private fun shouldBlock(domain: String): Boolean {
        val d = normalize(domain)
        if (DOH_BLOCK.any { d == it || d.endsWith(".$it") }) return true
        return blockedDomains.any { d == it || d.endsWith(".$it") }
    }

    private fun forwardDns(query: ByteArray): ByteArray? {
        return try {
            val sock = DatagramSocket()
            sock.soTimeout = DNS_TIMEOUT
            protect(sock)
            val addr = InetAddress.getByName(DNS_SERVER)
            sock.send(DatagramPacket(query, query.size, addr, 53))
            val buf = ByteArray(4096)
            val pkt = DatagramPacket(buf, buf.size)
            sock.receive(pkt)
            sock.close()
            buf.copyOf(pkt.length)
        } catch (e: Exception) {
            Log.e(TAG, "DNS forward error: $e")
            null
        }
    }

    // Block body (not expression body) so 'return null' is valid
    private fun parseDomain(dns: ByteArray): String? {
        return try {
            if (dns.size < 13) {
                null
            } else {
                var pos = 12
                val labels = mutableListOf<String>()
                while (pos < dns.size) {
                    val l = dns[pos].toInt() and 0xFF
                    if (l == 0) break
                    if (l >= 0xC0 || pos + 1 + l > dns.size) return null
                    labels.add(String(dns, pos + 1, l))
                    pos += 1 + l
                }
                labels.joinToString(".")
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun buildNxDomain(query: ByteArray): ByteArray {
        val r = query.copyOf()
        r[2] = 0x81.toByte()
        r[3] = 0x83.toByte()
        for (i in 6..11) r[i] = 0
        return r
    }

    private fun buildReply(origIp: ByteArray, dnsResp: ByteArray, ipLen: Int): ByteArray? {
        return try {
            val srcIp   = origIp.copyOfRange(12, 16)
            val dstIp   = origIp.copyOfRange(16, 20)
            val srcPort = origIp.copyOfRange(ipLen, ipLen + 2)
            val dstPort = origIp.copyOfRange(ipLen + 2, ipLen + 4)

            val udpLen = 8 + dnsResp.size

            val udp = ByteArray(8)
            dstPort.copyInto(udp, 0)
            srcPort.copyInto(udp, 2)
            udp[4] = (udpLen shr 8).toByte()
            udp[5] = (udpLen and 0xFF).toByte()

            val ip    = origIp.copyOfRange(0, ipLen)
            val total = ipLen + udpLen
            ip[2]  = (total shr 8).toByte()
            ip[3]  = (total and 0xFF).toByte()
            ip[6]  = 0; ip[7] = 0
            ip[8]  = 64
            dstIp.copyInto(ip, 12)
            srcIp.copyInto(ip, 16)
            ip[10] = 0; ip[11] = 0
            val cs = ipChecksum(ip)
            ip[10] = (cs shr 8).toByte()
            ip[11] = (cs and 0xFF).toByte()

            val out = ByteArray(ip.size + udp.size + dnsResp.size)
            ip.copyInto(out, 0)
            udp.copyInto(out, ip.size)
            dnsResp.copyInto(out, ip.size + udp.size)
            out
        } catch (_: Exception) {
            null
        }
    }

    private fun ipChecksum(header: ByteArray): Int {
        var sum = 0
        var i = 0
        while (i < header.size - 1) {
            sum += ((header[i].toInt() and 0xFF) shl 8) or (header[i + 1].toInt() and 0xFF)
            i += 2
        }
        if (header.size % 2 != 0) {
            sum += (header.last().toInt() and 0xFF) shl 8
        }
        while (sum ushr 16 != 0) {
            sum = (sum and 0xFFFF) + (sum ushr 16)
        }
        return sum.inv() and 0xFFFF
    }

    private fun normalize(d: String): String {
        return d.lowercase()
            .removePrefix("https://")
            .removePrefix("http://")
            .removePrefix("www.")
            .split("/")
            .first()
            .trimEnd('.')
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(NotificationChannel(
                    CHANNEL_ID, "StayOff VPN",
                    NotificationManager.IMPORTANCE_MIN).apply {
                        setShowBadge(false)
                        setSound(null, null)
                    })
        }
    }

    private fun buildNotification(): Notification {
        val stopPi = PendingIntent.getService(
            this, 0,
            Intent(this, FocusGuardVpnService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION") Notification.Builder(this)
        }
        return b.setContentTitle("Stay Off Active")
            .setContentText("Blocking adult sites")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .addAction(android.R.drawable.ic_delete, "Stop", stopPi)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        running.set(false)
        thread?.interrupt()
        thread = null
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
        super.onDestroy()
    }
}