package com.talla.speciality.data

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.util.UUID

data class ScaleDevice(
    val address: String,
    val name: String,
    val family: ScaleFamily,
    val rssi: Int,
)

data class ScaleUiState(
    val scanning: Boolean = false,
    val connectingAddress: String? = null,
    val devices: List<ScaleDevice> = emptyList(),
    val connectedAddress: String? = null,
    val connectedName: String? = null,
    val connectedFamily: ScaleFamily? = null,
    val weightGrams: Double = 0.0,
    val flowGramsPerSecond: Double? = null,
    val timerSeconds: Int? = null,
    val error: String? = null,
)

class CoffeeScaleManager(context: Context) {
    private val appContext = context.applicationContext
    private val adapter: BluetoothAdapter? = appContext.getSystemService(BluetoothManager::class.java)?.adapter
    private val handler = Handler(Looper.getMainLooper())
    private val devices = linkedMapOf<String, BluetoothDevice>()
    private val mutableState = MutableStateFlow(ScaleUiState())
    val state: StateFlow<ScaleUiState> = mutableState.asStateFlow()

    private var gatt: BluetoothGatt? = null
    private var commandCharacteristic: BluetoothGattCharacteristic? = null
    private var activeFamily: ScaleFamily? = null
    private var ginaCalibration = 1.0
    private var ginaTareOffset: Double? = null
    private var hiroiaUnitCommandPending = false
    private var hiroiaModeCommandPending = false
    private val stopScan = Runnable { stopScanning() }

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val advertisedServices = result.scanRecord?.serviceUuids.orEmpty().map { it.uuid }
            val name = result.scanRecord?.deviceName ?: result.device.name
            val family = ScaleFamily.detect(name, advertisedServices) ?: return
            devices[result.device.address] = result.device
            val device = ScaleDevice(result.device.address, name?.takeIf(String::isNotBlank) ?: family.displayName, family, result.rssi)
            mutableState.update { current ->
                current.copy(devices = (current.devices.filterNot { it.address == device.address } + device).sortedBy { it.name }, error = null)
            }
        }

        override fun onScanFailed(errorCode: Int) {
            mutableState.update { it.copy(scanning = false, error = "Bluetooth scan failed ($errorCode)") }
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(connection: BluetoothGatt, status: Int, newState: Int) {
            when {
                status != BluetoothGatt.GATT_SUCCESS -> fail("Scale connection failed ($status)", connection)
                newState == BluetoothProfile.STATE_CONNECTED -> {
                    if (!connection.discoverServices()) fail("Could not start scale service discovery", connection)
                }
                newState == BluetoothProfile.STATE_DISCONNECTED -> {
                    connection.close()
                    if (gatt === connection) clearConnection()
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(connection: BluetoothGatt, status: Int) {
            val family = activeFamily ?: return fail("Scale type was lost during connection", connection)
            if (status != BluetoothGatt.GATT_SUCCESS) return fail("Could not read scale services", connection)
            val service = connection.getService(family.serviceUuid) ?: return fail("Unsupported scale Bluetooth profile", connection)
            val notify = service.getCharacteristic(family.notifyUuid) ?: return fail("Scale weight channel is unavailable", connection)
            commandCharacteristic = family.commandUuid?.let(service::getCharacteristic)
            if (family.commandUuid != null && commandCharacteristic == null) return fail("Scale controls are unavailable", connection)

            if (family == ScaleFamily.Gina) {
                val calibration = service.getCharacteristic(ScaleFamily.ginaCalibrationUuid)
                    ?: return fail("GINA calibration is unavailable", connection)
                if (!connection.readCharacteristic(calibration)) fail("Could not read GINA calibration", connection)
            } else {
                enableNotifications(connection, notify)
            }
        }

        override fun onDescriptorWrite(connection: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            if (descriptor.uuid != CCCD_UUID || connection !== gatt) return
            if (status != BluetoothGatt.GATT_SUCCESS) {
                fail("Could not subscribe to scale updates", connection)
                return
            }
            markConnected(connection)
        }

        override fun onCharacteristicChanged(connection: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) {
            receiveTelemetry(value)
        }

        @Deprecated("Used below Android 13")
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(connection: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            receiveTelemetry(characteristic.value ?: return)
        }

        override fun onCharacteristicRead(connection: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray, status: Int) {
            receiveCalibration(connection, characteristic, value, status)
        }

        @Deprecated("Used below Android 13")
        @Suppress("DEPRECATION")
        override fun onCharacteristicRead(connection: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            receiveCalibration(connection, characteristic, characteristic.value ?: return, status)
        }
    }

    @SuppressLint("MissingPermission")
    fun scan(durationMillis: Long = 6_000) {
        val bluetoothAdapter = adapter
        if (bluetoothAdapter == null) {
            mutableState.update { it.copy(error = "Bluetooth Low Energy is not supported on this device") }
            return
        }
        if (!bluetoothAdapter.isEnabled) {
            mutableState.update { it.copy(error = "Turn on Bluetooth to find a coffee scale") }
            return
        }
        devices.clear()
        handler.removeCallbacks(stopScan)
        val scanner = bluetoothAdapter.bluetoothLeScanner
        if (scanner == null) {
            mutableState.update { it.copy(error = "Bluetooth scanning is unavailable on this device") }
            return
        }
        scanner.startScan(scanCallback)
        mutableState.update { it.copy(scanning = true, devices = emptyList(), error = null) }
        handler.postDelayed(stopScan, durationMillis)
    }

    @SuppressLint("MissingPermission")
    fun stopScanning() {
        handler.removeCallbacks(stopScan)
        adapter?.bluetoothLeScanner?.stopScan(scanCallback)
        mutableState.update { it.copy(scanning = false) }
    }

    @SuppressLint("MissingPermission")
    @Suppress("DEPRECATION")
    fun connect(address: String) {
        val device = devices[address]
        val selected = mutableState.value.devices.firstOrNull { it.address == address }
        if (device == null || selected == null) {
            mutableState.update { it.copy(error = "This scale is no longer available. Scan again.") }
            return
        }
        stopScanning()
        disconnect()
        activeFamily = selected.family
        ginaCalibration = 1.0
        ginaTareOffset = null
        hiroiaUnitCommandPending = false
        hiroiaModeCommandPending = false
        mutableState.update { it.copy(connectingAddress = address, error = null) }
        val connection = device.connectGatt(
            appContext,
            false,
            gattCallback,
            BluetoothDevice.TRANSPORT_LE,
            BluetoothDevice.PHY_LE_1M_MASK,
            handler,
        )
        gatt = connection
        if (connection == null) {
            clearConnection()
            mutableState.update { it.copy(error = "Could not start the scale connection") }
        }
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        gatt?.disconnect()
        gatt?.close()
        clearConnection()
    }

    fun perform(action: ScaleAction) {
        val family = activeFamily ?: return
        val activeConnection = gatt ?: return
        if (family == ScaleFamily.Gina && action == ScaleAction.Tare) {
            ginaTareOffset = mutableState.value.weightGrams + (ginaTareOffset ?: 0.0)
            mutableState.update { it.copy(weightGrams = 0.0, flowGramsPerSecond = null) }
            return
        }
        ScalePacketParser.command(family, action).forEachIndexed { index, bytes ->
            handler.postDelayed({
                if (gatt === activeConnection && activeFamily == family) writeCommand(bytes)
            }, index * 250L)
        }
        if (action == ScaleAction.Tare) mutableState.update { it.copy(weightGrams = 0.0, flowGramsPerSecond = null) }
    }

    fun clearError() = mutableState.update { it.copy(error = null) }

    @SuppressLint("MissingPermission")
    private fun enableNotifications(connection: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
        if (!connection.setCharacteristicNotification(characteristic, true)) return fail("Could not enable scale updates", connection)
        val descriptor = characteristic.getDescriptor(CCCD_UUID) ?: return fail("Scale notification setup is unavailable", connection)
        val started = if (Build.VERSION.SDK_INT >= 33) {
            connection.writeDescriptor(descriptor, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE) == BluetoothStatusCodes.SUCCESS
        } else {
            @Suppress("DEPRECATION")
            descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            @Suppress("DEPRECATION")
            connection.writeDescriptor(descriptor)
        }
        if (!started) return fail("Could not subscribe to scale updates", connection)
    }

    @SuppressLint("MissingPermission")
    private fun markConnected(connection: BluetoothGatt) {
        val selected = mutableState.value.devices.firstOrNull { it.address == connection.device.address }
        mutableState.update {
            it.copy(
                connectingAddress = null,
                connectedAddress = connection.device.address,
                connectedName = selected?.name ?: activeFamily?.displayName,
                connectedFamily = activeFamily,
                weightGrams = 0.0,
                flowGramsPerSecond = null,
                timerSeconds = null,
                error = null,
            )
        }
    }

    @SuppressLint("MissingPermission")
    private fun receiveCalibration(connection: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray, status: Int) {
        if (characteristic.uuid != ScaleFamily.ginaCalibrationUuid) return
        if (status != BluetoothGatt.GATT_SUCCESS) return fail("Could not read GINA calibration", connection)
        ginaCalibration = ScalePacketParser.ginaCalibration(value) ?: return fail("GINA returned invalid calibration", connection)
        val notify = connection.getService(ScaleFamily.Gina.serviceUuid)?.getCharacteristic(ScaleFamily.Gina.notifyUuid)
            ?: return fail("GINA weight channel is unavailable", connection)
        enableNotifications(connection, notify)
    }

    private fun receiveTelemetry(bytes: ByteArray) {
        val family = activeFamily ?: return
        val telemetry = ScalePacketParser.parse(family, bytes, ginaCalibration) ?: return
        var weight = telemetry.weightGrams
        if (family == ScaleFamily.Gina) {
            if (ginaTareOffset == null) ginaTareOffset = weight
            weight -= ginaTareOffset ?: 0.0
        } else if (family == ScaleFamily.Hiroia) {
            scheduleHiroiaSetupCommands(bytes)
        }
        mutableState.update {
            it.copy(weightGrams = weight, flowGramsPerSecond = telemetry.flowGramsPerSecond, timerSeconds = telemetry.timerSeconds)
        }
    }

    @SuppressLint("MissingPermission")
    private fun writeCommand(bytes: ByteArray) {
        val connection = gatt ?: return
        val characteristic = commandCharacteristic ?: return
        val supportsWrite = (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE) != 0
        val supportsWriteWithoutResponse =
            (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0
        val preferWriteWithoutResponse = activeFamily == ScaleFamily.Mantabrew
        val writeType = when {
            preferWriteWithoutResponse && supportsWriteWithoutResponse -> BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
            supportsWrite -> BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            supportsWriteWithoutResponse -> BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
            else -> return
        }
        if (Build.VERSION.SDK_INT >= 33) {
            connection.writeCharacteristic(characteristic, bytes, writeType)
        } else {
            @Suppress("DEPRECATION")
            characteristic.value = bytes
            @Suppress("DEPRECATION")
            connection.writeCharacteristic(characteristic)
        }
    }

    private fun scheduleHiroiaSetupCommands(bytes: ByteArray) {
        val commands = ScalePacketParser.hiroiaSetupCommands(bytes).filter { command ->
            when (command.firstOrNull()?.toInt()?.and(0xFF)) {
                0x0B -> if (hiroiaUnitCommandPending) false else {
                    hiroiaUnitCommandPending = true
                    true
                }
                0x04 -> if (hiroiaModeCommandPending) false else {
                    hiroiaModeCommandPending = true
                    true
                }
                else -> false
            }
        }
        val activeConnection = gatt
        commands.forEachIndexed { index, command ->
            handler.postDelayed({
                if (gatt === activeConnection && activeFamily == ScaleFamily.Hiroia) writeCommand(command)
            }, index * 200L)
        }
        if (commands.isNotEmpty()) {
            handler.postDelayed({
                hiroiaUnitCommandPending = false
                hiroiaModeCommandPending = false
            }, 500L)
        }
    }

    @SuppressLint("MissingPermission")
    private fun fail(message: String, connection: BluetoothGatt) {
        connection.disconnect()
        connection.close()
        if (gatt === connection) clearConnection()
        mutableState.update { it.copy(error = message) }
    }

    private fun clearConnection() {
        gatt = null
        commandCharacteristic = null
        activeFamily = null
        ginaCalibration = 1.0
        ginaTareOffset = null
        hiroiaUnitCommandPending = false
        hiroiaModeCommandPending = false
        mutableState.update {
            it.copy(
                connectingAddress = null, connectedAddress = null, connectedName = null, connectedFamily = null,
                weightGrams = 0.0, flowGramsPerSecond = null, timerSeconds = null,
            )
        }
    }

    companion object {
        private val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
