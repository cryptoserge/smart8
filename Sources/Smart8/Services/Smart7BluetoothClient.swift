#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

public enum Smart7ClientError: Error, CustomStringConvertible {
    case bluetoothUnavailable(CBManagerState)
    case notConnected
    case serviceMissing
    case characteristicMissing(String)
    case characteristicNotWritable
    case passwordNotReceived
    case passwordMismatch

    public var description: String {
        switch self {
        case let .bluetoothUnavailable(state):
            return "Bluetooth is unavailable: \(state.rawValue)"
        case .notConnected:
            return "Smart7 is not connected"
        case .serviceMissing:
            return "Smart7 service 0x1000 was not found"
        case let .characteristicMissing(uuid):
            return "Smart7 characteristic \(uuid) was not found"
        case .characteristicNotWritable:
            return "Smart7 write characteristic is not writable"
        case .passwordNotReceived:
            return "No six-digit challenge has been received"
        case .passwordMismatch:
            return "The entered code does not match the code sent by Smart7"
        }
    }
}

public enum Smart7ClientEvent {
    case bluetoothState(CBManagerState)
    case scanning
    case discovered(name: String, identifier: UUID, rssi: Int)
    case connecting(name: String)
    case connected(name: String)
    case ready
    case authenticated
    case passwordReceived
    case frame(Smart7Frame)
    case disconnected(Error?)
    case error(Error)
}

public final class Smart7BluetoothClient: NSObject {
    public var onEvent: ((Smart7ClientEvent) -> Void)?
    public var onLog: ((DiagnosticLogEntry) -> Void)?
    public var automaticallyConnectFirstEVS70 = true

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var discoveredPeripheral: CBPeripheral?
    private var discoveredName: String?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    private var pendingPassword: String?
    private var notificationParser = Smart7NotificationParser()
    private var didSendInitialRequest = false

    private lazy var sendQueue = Smart7SendQueue { [weak self] frame in
        guard let self else { return }
        try self.writeNow(label: frame.label, plain: frame.plain)
    }

    private let serviceUUID = CBUUID(string: Smart7Protocol.serviceUUID)
    private let writeUUID = CBUUID(string: Smart7Protocol.writeUUID)
    private let notifyUUID = CBUUID(string: Smart7Protocol.notifyUUID)

    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    public func startScanning() throws {
        guard central.state == .poweredOn else {
            throw Smart7ClientError.bluetoothUnavailable(central.state)
        }
        log(.event, "検索開始: \(Smart7Protocol.deviceNameSubstring)")
        onEvent?(.scanning)
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    public func stopScanning() {
        central.stopScan()
        log(.event, "検索停止")
    }

    public func connectDiscoveredPeripheral() throws {
        guard let discoveredPeripheral else {
            throw Smart7ClientError.notConnected
        }
        connect(discoveredPeripheral, name: discoveredName ?? discoveredPeripheral.name ?? "EVS-70")
    }

    public func disconnect(sendCancel: Bool = false) {
        if sendCancel, writeCharacteristic != nil {
            try? writeNow(label: "接続取消", plain: Smart7Protocol.cancelSessionFrame())
        }
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        clearConnectionState()
    }

    @discardableResult
    public func submitPassword(_ entered: String) throws -> Bool {
        guard let pendingPassword else { throw Smart7ClientError.passwordNotReceived }
        guard entered.trimmingCharacters(in: .whitespacesAndNewlines) == pendingPassword else {
            throw Smart7ClientError.passwordMismatch
        }
        try writeNow(label: "接続許可", plain: Smart7Protocol.acceptSessionFrame())
        onEvent?(.authenticated)
        return true
    }

    public func acceptReceivedPassword() throws {
        guard pendingPassword != nil else { throw Smart7ClientError.passwordNotReceived }
        try writeNow(label: "接続許可", plain: Smart7Protocol.acceptSessionFrame())
        onEvent?(.authenticated)
    }

    public func requestStatus() {
        enqueueRegular(label: "状態問い合わせ", plainBuilder: Smart7Protocol.getStatusFrame)
    }

    public func sendRecipe(_ recipe: Smart7Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let sequence = try Smart7Protocol.recipeSequence(
                temperatureCelsius: recipe.temperatureCelsius,
                steps: recipe.steps
            )
            sendQueue.enqueueSequence(sequence, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    public func stopBrewing(completion: ((Result<Void, Error>) -> Void)? = nil) {
        sendQueue.cancelRegularFrames()
        enqueuePriority(label: "抽出停止", plainBuilder: { try Smart7Protocol.brewControlFrame(.stop) }, completion: completion)
    }

    public func startDrain(completion: ((Result<Void, Error>) -> Void)? = nil) {
        sendQueue.cancelRegularFrames()
        enqueuePriority(label: "排水開始", plainBuilder: { try Smart7Protocol.drainControlFrame(start: true) }, completion: completion)
    }

    public func stopDrain(completion: ((Result<Void, Error>) -> Void)? = nil) {
        sendQueue.cancelRegularFrames()
        enqueuePriority(label: "排水停止", plainBuilder: { try Smart7Protocol.drainControlFrame(start: false) }, completion: completion)
    }

    private func enqueueRegular(
        label: String,
        plainBuilder: () throws -> Data,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        do {
            let frame = Smart7ScheduledFrame(label: label, delayBeforeMilliseconds: 0, plain: try plainBuilder())
            sendQueue.enqueueSequence([frame]) { result in
                completion?(result)
            }
        } catch {
            completion?(.failure(error))
            onEvent?(.error(error))
        }
    }

    private func enqueuePriority(
        label: String,
        plainBuilder: () throws -> Data,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        do {
            sendQueue.enqueuePriority(label: label, plain: try plainBuilder(), completion: completion)
        } catch {
            completion?(.failure(error))
            onEvent?(.error(error))
        }
    }

    private func writeNow(label: String, plain: Data) throws {
        guard let peripheral, peripheral.state == .connected else {
            throw Smart7ClientError.notConnected
        }
        guard let characteristic = writeCharacteristic else {
            throw Smart7ClientError.characteristicMissing(Smart7Protocol.writeUUID)
        }
        let encoded = try Smart7Protocol.encodeEnvelope(plain)
        let writeType: CBCharacteristicWriteType
        if characteristic.properties.contains(.writeWithoutResponse) {
            writeType = .withoutResponse
        } else if characteristic.properties.contains(.write) {
            writeType = .withResponse
        } else {
            throw Smart7ClientError.characteristicNotWritable
        }
        log(.outbound, "\(label) writeType=\(writeType == .withoutResponse ? "withoutResponse" : "withResponse")", plain: plain, encoded: encoded)
        peripheral.writeValue(encoded, for: characteristic, type: writeType)
    }

    private func clearConnectionState() {
        writeCharacteristic = nil
        notifyCharacteristic = nil
        pendingPassword = nil
        didSendInitialRequest = false
        notificationParser = Smart7NotificationParser()
        sendQueue.cancelRegularFrames()
    }

    private func connect(_ peripheral: CBPeripheral, name: String) {
        stopScanning()
        self.peripheral = peripheral
        peripheral.delegate = self
        log(.event, "接続開始 name=\(name)")
        onEvent?(.connecting(name: name))
        central.connect(peripheral)
    }

    private func handleNotification(_ encoded: Data) {
        log(.inbound, "通知受信", encoded: encoded)
        do {
            let frames = try notificationParser.append(encoded)
            for frame in frames {
                log(.inbound, "復号 frame command=0x\(String(format: "%02X", frame.command)) checksum=\(frame.checksumIsValid)", plain: frame.raw)
                onEvent?(.frame(frame))
                switch frame.command {
                case Smart7Command.passwordChallenge.rawValue:
                    pendingPassword = try Smart7Protocol.password(from: frame)
                    onEvent?(.passwordReceived)
                    try writeNow(label: "接続許可", plain: Smart7Protocol.acceptSessionFrame())
                    onEvent?(.authenticated)
                case Smart7Command.keepaliveRequest.rawValue:
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) { [weak self] in
                        self?.enqueuePriority(label: "接続維持応答", plainBuilder: Smart7Protocol.keepaliveReplyFrame)
                    }
                default:
                    break
                }
            }
        } catch {
            log(.error, "通知処理失敗: \(error)")
            onEvent?(.error(error))
        }
    }

    private func log(_ direction: DiagnosticLogEntry.Direction, _ message: String, plain: Data? = nil, encoded: Data? = nil) {
        onLog?(DiagnosticLogEntry(
            direction: direction,
            message: message,
            plainHex: plain.map(Smart7Protocol.hex),
            encodedHex: encoded.map(Smart7Protocol.hex)
        ))
    }
}

extension Smart7BluetoothClient: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log(.event, "Bluetooth state=\(central.state.rawValue)")
        onEvent?(.bluetoothState(central.state))
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? ""
        guard name.localizedCaseInsensitiveContains(Smart7Protocol.deviceNameSubstring) else { return }
        discoveredPeripheral = peripheral
        discoveredName = name
        log(.event, "発見 name=\(name) id=\(peripheral.identifier) rssi=\(RSSI.intValue)")
        onEvent?(.discovered(name: name, identifier: peripheral.identifier, rssi: RSSI.intValue))
        if automaticallyConnectFirstEVS70, self.peripheral == nil {
            connect(peripheral, name: name)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(.event, "接続完了 name=\(peripheral.name ?? "EVS-70")")
        onEvent?(.connected(name: peripheral.name ?? "EVS-70"))
        peripheral.discoverServices([serviceUUID])
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnectionState()
        log(.error, "接続失敗: \(error?.localizedDescription ?? "unknown")")
        onEvent?(.error(error ?? Smart7ClientError.notConnected))
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        clearConnectionState()
        log(.event, "切断: \(error?.localizedDescription ?? "normal")")
        onEvent?(.disconnected(error))
    }
}

extension Smart7BluetoothClient: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            log(.error, "サービス探索失敗: \(error.localizedDescription)")
            onEvent?(.error(error))
            return
        }
        for service in peripheral.services ?? [] {
            log(.event, "service=\(service.uuid.uuidString)")
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            onEvent?(.error(Smart7ClientError.serviceMissing))
            return
        }
        peripheral.discoverCharacteristics([writeUUID, notifyUUID], for: service)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            log(.error, "特性探索失敗: \(error.localizedDescription)")
            onEvent?(.error(error))
            return
        }
        for characteristic in service.characteristics ?? [] {
            log(.event, "characteristic=\(characteristic.uuid.uuidString) properties=\(characteristic.properties.rawValue)")
            switch characteristic.uuid {
            case writeUUID:
                writeCharacteristic = characteristic
            case notifyUUID:
                notifyCharacteristic = characteristic
            default:
                break
            }
        }
        guard writeCharacteristic != nil else {
            onEvent?(.error(Smart7ClientError.characteristicMissing(Smart7Protocol.writeUUID)))
            return
        }
        guard let notifyCharacteristic else {
            onEvent?(.error(Smart7ClientError.characteristicMissing(Smart7Protocol.notifyUUID)))
            return
        }
        peripheral.setNotifyValue(true, for: notifyCharacteristic)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            log(.error, "通知有効化失敗: \(error.localizedDescription)")
            onEvent?(.error(error))
            return
        }
        guard characteristic.uuid == notifyUUID, characteristic.isNotifying else { return }
        log(.event, "通知有効化完了。500ms後にパスワード要求")
        onEvent?(.ready)
        guard !didSendInitialRequest else { return }
        didSendInitialRequest = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
            self?.enqueuePriority(label: "パスワード要求", plainBuilder: Smart7Protocol.requestPasswordFrame)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            log(.error, "通知受信失敗: \(error.localizedDescription)")
            onEvent?(.error(error))
            return
        }
        guard characteristic.uuid == notifyUUID, let data = characteristic.value else { return }
        handleNotification(data)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            log(.error, "書込み応答エラー: \(error.localizedDescription)")
            onEvent?(.error(error))
        } else {
            log(.event, "書込み応答 success characteristic=\(characteristic.uuid.uuidString)")
        }
    }
}
#endif
