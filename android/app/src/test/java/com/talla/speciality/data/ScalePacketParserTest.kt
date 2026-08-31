package com.talla.speciality.data

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ScalePacketParserTest {
    @Test
    fun parsesBookooWeightFlowAndTimerWithChecksum() {
        val packet = ByteArray(20)
        packet[0] = 0x03
        packet[1] = 0x0B
        putUnsigned24(packet, 2, 123_000)
        putUnsigned24(packet, 7, 12_345)
        packet[11] = 0x00
        packet[12] = 0xEA.toByte()
        packet[19] = packet.take(19).fold(0) { value, byte -> value xor (byte.toInt() and 0xFF) }.toByte()

        val telemetry = ScalePacketParser.parse(ScaleFamily.Bookoo, packet)!!

        assertEquals(123.45, telemetry.weightGrams, 0.001)
        assertEquals(2.34, telemetry.flowGramsPerSecond!!, 0.001)
        assertEquals(123, telemetry.timerSeconds)
        packet[19] = (packet[19].toInt() xor 1).toByte()
        assertNull(ScalePacketParser.parse(ScaleFamily.Bookoo, packet))
    }

    @Test
    fun parsesMantabrewSignedWeight() {
        val packet = byteArrayOf(0x01, 0x02, 0, 0x10, 0, 0x04, 0xD2.toByte())
        assertEquals(-123.4, ScalePacketParser.parse(ScaleFamily.Mantabrew, packet)!!.weightGrams, 0.001)
    }

    @Test
    fun parsesHiroiaAndGinaCalibration() {
        val hiroia = byteArrayOf(0x01, 0, 0, 0, 0x8F.toByte(), 0x0C, 0)
        assertEquals(321.5, ScalePacketParser.parse(ScaleFamily.Hiroia, hiroia)!!.weightGrams, 0.001)

        val calibrationBytes = littleEndian(12_500)
        val calibration = ScalePacketParser.ginaCalibration(calibrationBytes)!!
        assertEquals(1.25, calibration, 0.0001)
        assertEquals(200.0, ScalePacketParser.parse(ScaleFamily.Gina, littleEndian(2_500), calibration)!!.weightGrams, 0.001)
    }

    @Test
    fun createsBookooTareCommandAndDetectsFamilies() {
        val command = ScalePacketParser.command(ScaleFamily.Bookoo, ScaleAction.Tare).single()
        assertArrayEquals(byteArrayOf(0x03, 0x0A, 0x01, 0, 0, 0x08), command)
        assertEquals(ScaleFamily.Bookoo, ScaleFamily.detect("BOOKOO_SC_U_1234", emptyList()))
        assertEquals(ScaleFamily.Hiroia, ScaleFamily.detect(null, listOf(ScaleFamily.Hiroia.serviceUuid)))
    }

    private fun putUnsigned24(target: ByteArray, offset: Int, value: Int) {
        target[offset] = (value shr 16).toByte()
        target[offset + 1] = (value shr 8).toByte()
        target[offset + 2] = value.toByte()
    }

    private fun littleEndian(value: Int) = byteArrayOf(value.toByte(), (value shr 8).toByte(), (value shr 16).toByte(), (value shr 24).toByte())
}
