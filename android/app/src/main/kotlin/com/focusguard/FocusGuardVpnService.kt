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
        const val TAG = "FocusGuardVPN"

        const val CHANNEL_ID = "focusguard_vpn"
        const val NOTIF_ID = 1001

        const val ACTION_START = "com.focusguard.START_VPN"
        const val ACTION_STOP = "com.focusguard.STOP_VPN"

        const val EXTRA_URLS = "blocked_urls"

        private const val DNS_SERVER = "8.8.8.8"
        private const val DNS_TIMEOUT = 4000

        // ONLY exact domains user selected
        val blockedDomains = mutableSetOf<String>()
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private val running = AtomicBoolean(false)
    private var vpnThread: Thread? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        when (intent?.action) {

            ACTION_STOP -> {
                stopVpn()
                return START_NOT_STICKY
            }

            ACTION_START -> {

                val urls =
                    intent.getStringArrayListExtra(EXTRA_URLS) ?: arrayListOf()

                blockedDomains.clear()

                blockedDomains.addAll(
                    urls.map { normalizeDomain(it) }
                        .filter { it.isNotBlank() }
                )

                Log.d(TAG, "Loaded blocked domains: $blockedDomains")

                if (blockedDomains.isEmpty()) {
                    stopVpn()
                    return START_NOT_STICKY
                }

                if (!running.get()) {
                    startVpn()
                }
            }
        }

        return START_STICKY
    }

    private fun startVpn() {

        try {

            createNotificationChannel()

            startForeground(
                NOTIF_ID,
                buildNotification()
            )

            val builder = Builder()
                .setSession("StayOff")
                .setMtu(1500)
                .addAddress("10.10.10.2", 32)

                // IMPORTANT:
                // Only DNS traffic goes through VPN.
                // This fixes internet/browser/search issues.
                .addRoute("8.8.8.8", 32)

                .addDnsServer("8.8.8.8")

            vpnInterface = builder.establish()

            if (vpnInterface == null) {
                stopVpn()
                return
            }

            running.set(true)

            vpnThread = Thread({
                runVpnLoop()
            }, "FocusGuardVpnThread")

            vpnThread?.start()

            Log.d(TAG, "VPN STARTED")

        } catch (e: Exception) {

            Log.e(TAG, "VPN START ERROR", e)

            stopVpn()
        }
    }

    private fun stopVpn() {

        running.set(false)

        try {
            vpnThread?.interrupt()
        } catch (_: Exception) {
        }

        vpnThread = null

        try {
            vpnInterface?.close()
        } catch (_: Exception) {
        }

        vpnInterface = null

        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } catch (_: Exception) {
        }

        stopSelf()

        Log.d(TAG, "VPN STOPPED")
    }

    private fun runVpnLoop() {

        val vpn = vpnInterface ?: return

        val input = FileInputStream(vpn.fileDescriptor)
        val output = FileOutputStream(vpn.fileDescriptor)

        val packet = ByteArray(32767)

        while (running.get()) {

            try {

                val length = input.read(packet)

                if (length <= 0) {
                    Thread.sleep(10)
                    continue
                }

                if (length < 28) {
                    continue
                }

                val version = packet[0].toInt() shr 4

                if (version != 4) {
                    continue
                }

                val headerLength = (packet[0].toInt() and 0x0F) * 4

                val protocol = packet[9].toInt() and 0xFF

                // Only UDP
                if (protocol != 17) {
                    continue
                }

                val destPort =
                    ((packet[headerLength + 2].toInt() and 0xFF) shl 8) or
                            (packet[headerLength + 3].toInt() and 0xFF)

                // Only DNS
                if (destPort != 53) {
                    continue
                }

                val dnsData =
                    packet.copyOfRange(headerLength + 8, length)

                val domain = parseDomain(dnsData)

                if (domain == null) {
                    continue
                }

                Log.d(TAG, "DNS REQUEST: $domain")

                if (shouldBlock(domain)) {

                    Log.d(TAG, "BLOCKED DOMAIN: $domain")

                    val blockedResponse =
                        buildNxDomainResponse(dnsData)

                    val responsePacket =
                        buildDnsResponsePacket(
                            originalPacket = packet,
                            dnsPayload = blockedResponse,
                            ipHeaderLength = headerLength
                        )

                    if (responsePacket != null) {
                        output.write(responsePacket)
                    }

                } else {

                    val upstreamResponse =
                        forwardDnsToGoogle(dnsData)

                    if (upstreamResponse != null) {

                        val responsePacket =
                            buildDnsResponsePacket(
                                originalPacket = packet,
                                dnsPayload = upstreamResponse,
                                ipHeaderLength = headerLength
                            )

                        if (responsePacket != null) {
                            output.write(responsePacket)
                        }
                    }
                }

            } catch (e: Exception) {

                Log.e(TAG, "VPN LOOP ERROR", e)

                try {
                    Thread.sleep(100)
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun shouldBlock(domain: String): Boolean {

        val normalized = normalizeDomain(domain)

        return blockedDomains.any {
            normalized == it ||
                    normalized.endsWith(".$it")
        }
    }

    private fun forwardDnsToGoogle(query: ByteArray): ByteArray? {

        return try {

            val socket = DatagramSocket()

            protect(socket)

            socket.soTimeout = DNS_TIMEOUT

            val address = InetAddress.getByName(DNS_SERVER)

            val requestPacket =
                DatagramPacket(
                    query,
                    query.size,
                    address,
                    53
                )

            socket.send(requestPacket)

            val responseBuffer = ByteArray(4096)

            val responsePacket =
                DatagramPacket(
                    responseBuffer,
                    responseBuffer.size
                )

            socket.receive(responsePacket)

            socket.close()

            responseBuffer.copyOf(responsePacket.length)

        } catch (e: Exception) {

            Log.e(TAG, "DNS FORWARD FAILED", e)

            null
        }
    }

    private fun parseDomain(dns: ByteArray): String? {

        return try {

            if (dns.size < 13) {
                return null
            }

            var position = 12

            val labels = mutableListOf<String>()

            while (position < dns.size) {

                val length = dns[position].toInt() and 0xFF

                if (length == 0) {
                    break
                }

                if (length >= 192) {
                    return null
                }

                if (position + length >= dns.size) {
                    return null
                }

                labels.add(
                    String(
                        dns,
                        position + 1,
                        length
                    )
                )

                position += (length + 1)
            }

            labels.joinToString(".")

        } catch (e: Exception) {

            null
        }
    }

    private fun buildNxDomainResponse(query: ByteArray): ByteArray {

        val response = query.copyOf()

        // Response + NXDOMAIN
        response[2] = 0x81.toByte()
        response[3] = 0x83.toByte()

        // No answers
        for (i in 6..11) {
            response[i] = 0
        }

        return response
    }

    private fun buildDnsResponsePacket(
        originalPacket: ByteArray,
        dnsPayload: ByteArray,
        ipHeaderLength: Int
    ): ByteArray? {

        return try {

            val sourceIp =
                originalPacket.copyOfRange(12, 16)

            val destIp =
                originalPacket.copyOfRange(16, 20)

            val sourcePort =
                originalPacket.copyOfRange(
                    ipHeaderLength,
                    ipHeaderLength + 2
                )

            val destPort =
                originalPacket.copyOfRange(
                    ipHeaderLength + 2,
                    ipHeaderLength + 4
                )

            val udpLength = 8 + dnsPayload.size

            val udpHeader = ByteArray(8)

            // swap ports
            destPort.copyInto(udpHeader, 0)
            sourcePort.copyInto(udpHeader, 2)

            udpHeader[4] = (udpLength shr 8).toByte()
            udpHeader[5] = (udpLength and 0xFF).toByte()

            val ipHeader =
                originalPacket.copyOfRange(0, ipHeaderLength)

            val totalLength = ipHeaderLength + udpLength

            ipHeader[2] = (totalLength shr 8).toByte()
            ipHeader[3] = (totalLength and 0xFF).toByte()

            ipHeader[8] = 64

            // swap IPs
            destIp.copyInto(ipHeader, 12)
            sourceIp.copyInto(ipHeader, 16)

            // reset checksum
            ipHeader[10] = 0
            ipHeader[11] = 0

            val checksum = calculateIpChecksum(ipHeader)

            ipHeader[10] = (checksum shr 8).toByte()
            ipHeader[11] = (checksum and 0xFF).toByte()

            val finalPacket =
                ByteArray(
                    ipHeader.size +
                            udpHeader.size +
                            dnsPayload.size
                )

            ipHeader.copyInto(finalPacket, 0)

            udpHeader.copyInto(
                finalPacket,
                ipHeader.size
            )

            dnsPayload.copyInto(
                finalPacket,
                ipHeader.size + udpHeader.size
            )

            finalPacket

        } catch (e: Exception) {

            Log.e(TAG, "PACKET BUILD ERROR", e)

            null
        }
    }

    private fun calculateIpChecksum(header: ByteArray): Int {

        var sum = 0

        var i = 0

        while (i < header.size - 1) {

            sum += (
                    ((header[i].toInt() and 0xFF) shl 8)
                            or
                            (header[i + 1].toInt() and 0xFF)
                    )

            i += 2
        }

        while ((sum shr 16) != 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }

        return sum.inv() and 0xFFFF
    }

    private fun normalizeDomain(domain: String): String {

        return domain.lowercase()
            .removePrefix("https://")
            .removePrefix("http://")
            .removePrefix("www.")
            .split("/")
            .first()
            .trim()
            .trimEnd('.')
    }

    private fun createNotificationChannel() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val channel = NotificationChannel(
                CHANNEL_ID,
                "StayOff VPN",
                NotificationManager.IMPORTANCE_LOW
            )

            channel.setSound(null, null)
            channel.enableVibration(false)
            channel.setShowBadge(false)

            val manager =
                getSystemService(NotificationManager::class.java)

            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {

        val stopIntent = Intent(
            this,
            FocusGuardVpnService::class.java
        ).apply {
            action = ACTION_STOP
        }

        val stopPendingIntent =
            PendingIntent.getService(
                this,
                0,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
            )

        val builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

        return builder
            .setContentTitle("StayOff Active")
            .setContentText("Selected websites are blocked")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_delete,
                "Stop",
                stopPendingIntent
            )
            .build()
    }

    override fun onDestroy() {

        stopVpn()

        super.onDestroy()
    }
}