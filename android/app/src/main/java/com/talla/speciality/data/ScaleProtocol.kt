package com.talla.speciality.data

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.UUID

enum class ScaleFamily(val displayName: String, val serviceUuid: UUID, val notifyUuid: UUID, val commandUuid: UUID?) {
    Bookoo("BOOKOO", bluetoothUuid("0FFE"), bluetoothUuid("FF11"), bluetoothUuid("FF12")),
    Mantabrew("MANTABREW WeighMaster 2.0", bluetoothUuid("FFF0"), bluetoothUuid("FFF4"), bluetoothUuid("FFF1")),
    Hiroia("HIROIA JIMMY", UUID.fromString("06C31822-8682-4744-9211-FEBC93E3BECE"), UUID.fromString("06C31824-8682-4744-9211-FEBC93E3BECE"), UUID.fromString("06C31823-8682-4744-9211-FEBC93E3BECE")),
    Gina("GOAT STORY GINA", UUID.fromString("91341521-BAC2-42D9-BBB3-942F7A10976C"), UUID.fromString("91341522-BAC2-42D9-BBB3-942F7A10976C"), null);

    companion object {
        val ginaCalibrationUuid: UUID = UUID.fromString("91341523-BAC2-42D9-BBB3-942F7A10976C")

        fun detect(name: String?, advertisedServices: Collection<UUID>): ScaleFamily? {
            val normalized = name.orEmpty().lowercase().replace('-', '_').replace(' ', '_')
            return when {
                normalized.startsWith("bookoo_sc_") || Bookoo.serviceUuid in advertisedServices -> Bookoo
                normalized.contains("weighmaster") || normalized.contains("mantabrew") || Mantabrew.serviceUuid in advertisedServices -> Mantabrew
                normalized.startsWith("hiroia") || Hiroia.serviceUuid in advertisedServices -> Hiroia
                normalized.contains("gina") || Gina.serviceUuid in advertisedServices -> Gina
                else -> null
            }
        }
    }
}

data class ScaleTelemetry(val weightGrams: Double, val flowGramsPerSecond: Double? = null, val timerSeconds: Int? = null)

object ScalePacketParser {
    fun parse(family: ScaleFamily, bytes: ByteArray, ginaCalibration: Double = 1.0): ScaleTelemetry? = when (family) {
        ScaleFamily.Bookoo -> bookoo(bytes)
        ScaleFamily.Mantabrew -> mantabrew(bytes)
        ScaleFamily.Hiroia -> hiroia(bytes)
        ScaleFamily.Gina -> gina(bytes, ginaCalibration)
    }

    fun ginaCalibration(bytes: ByteArray): Double? {
        if (bytes.size < 4) return null
        val raw = ByteBuffer.wrap(bytes.copyOf(4)).order(ByteOrder.LITTLE_ENDIAN).int.toLong() and 0xffff_ffffL
        return (raw.toDouble() / 10_000).takeIf { it.isFinite() && it > 0 }
    }

    fun command(family: ScaleFamily, action: ScaleAction): List<ByteArray> = when (family) {
        ScaleFamily.Bookoo -> when (action) {
            ScaleAction.Tare -> listOf(bookooCommand(0x01))
            ScaleAction.StartTimer -> listOf(bookooCommand(0x04))
            ScaleAction.PauseTimer -> listOf(bookooCommand(0x05))
            ScaleAction.StopTimer -> listOf(bookooCommand(0x05), bookooCommand(0x06))
        }
        ScaleFamily.Mantabrew -> when (action) {
            ScaleAction.Tare -> listOf(byteArrayOf(0x02), byteArrayOf(0x05, 0x00))
            ScaleAction.StartTimer -> listOf(byteArrayOf(0x52, 0x0B, 0x01, 0, 0, 0, 0))
            ScaleAction.PauseTimer -> listOf(byteArrayOf(0x52, 0x0B, 0x00, 0, 0, 0, 0))
            ScaleAction.StopTimer -> listOf(byteArrayOf(0x52, 0x0B, 0x02, 0, 0, 0, 0))
        }
        ScaleFamily.Hiroia -> if (action == ScaleAction.Tare) listOf(byteArrayOf(0x07, 0x00)) else emptyList()
        ScaleFamily.Gina -> emptyList()
    }

    private fun bookoo(bytes: ByteArray): ScaleTelemetry? {
        if (bytes.size != 20 || u(bytes[0]) != 0x03 || u(bytes[1]) != 0x0B) return null
        val checksum = bytes.dropLast(1).fold(0) { value, byte -> value xor u(byte) }
        if (checksum != u(bytes[19])) return null
        val milliseconds = unsigned24(bytes[2], bytes[3], bytes[4])
        val rawWeight = unsigned24(bytes[7], bytes[8], bytes[9])
        val rawFlow = (u(bytes[11]) shl 8) or u(bytes[12])
        val multiplier = if (u(bytes[5]) == 2) 28.349_523_125 else 1.0
        val weightSign = if (isNegative(bytes[6])) -1 else 1
        val flowSign = if (isNegative(bytes[10])) -1 else 1
        return ScaleTelemetry(weightSign * (rawWeight / 100.0) * multiplier, flowSign * (rawFlow / 100.0) * multiplier, milliseconds / 1_000)
    }

    private fun mantabrew(bytes: ByteArray): ScaleTelemetry? {
        if (bytes.size < 7 || u(bytes[0]) != 0x01 || u(bytes[1]) != 0x02) return null
        val rawWeight = (u(bytes[4]) shl 16) or (u(bytes[5]) shl 8) or u(bytes[6])
        val signed = if ((u(bytes[3]) and 0x10) != 0) -rawWeight else rawWeight
        return ScaleTelemetry(signed / 10.0)
    }

    private fun hiroia(bytes: ByteArray): ScaleTelemetry? {
        if (bytes.size < 7) return null
        val rawMode = u(bytes[0])
        val isOunce = rawMode > 0x08
        var rawWeight = (u(bytes[5]) shl 8) or u(bytes[4])
        if (u(bytes[6]) == 0xFF) rawWeight = -(65_536 - rawWeight)
        val grams = if (isOunce) (rawWeight / 1_000.0) * 28.349_523_125 else rawWeight / 10.0
        return ScaleTelemetry(grams)
    }

    private fun gina(bytes: ByteArray, calibration: Double): ScaleTelemetry? {
        if (bytes.size < 4 || !calibration.isFinite() || calibration <= 0) return null
        val raw = ByteBuffer.wrap(bytes.copyOf(4)).order(ByteOrder.LITTLE_ENDIAN).int.toLong() and 0xffff_ffffL
        return ScaleTelemetry((raw / 10.0) / calibration)
    }

    private fun bookooCommand(command: Int): ByteArray {
        val bytes = byteArrayOf(0x03, 0x0A, command.toByte(), 0, 0, 0)
        bytes[5] = bytes.take(5).fold(0) { value, byte -> value xor u(byte) }.toByte()
        return bytes
    }

    private fun unsigned24(high: Byte, middle: Byte, low: Byte): Int = (u(high) shl 16) or (u(middle) shl 8) or u(low)
    private fun isNegative(byte: Byte): Boolean = u(byte) == 1 || u(byte) == 0x2D
    private fun u(byte: Byte): Int = byte.toInt() and 0xFF
}

enum class ScaleAction { Tare, StartTimer, PauseTimer, StopTimer }

private fun bluetoothUuid(shortUuid: String): UUID = UUID.fromString("0000${shortUuid.lowercase()}-0000-1000-8000-00805f9b34fb")
