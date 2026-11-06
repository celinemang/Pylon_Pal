import CoreBluetooth

/// BLE central: finds "PylonPal", writes 1-byte state. Auto-reconnects.
final class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let service = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let characteristic = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

    @Published var connected = false
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var char: CBCharacteristic?
    private var lastState: UInt8 = 0

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func send(_ state: PylonState) {
        lastState = state.rawValue
        guard let p = peripheral, let c = char else { return }
        p.writeValue(Data([state.rawValue]), for: c, type: .withoutResponse)
    }

    private func scan() {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [Self.service])
    }

    func centralManagerDidUpdateState(_ c: CBCentralManager) { scan() }

    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        peripheral = p; p.delegate = self
        c.stopScan(); c.connect(p)
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) { p.discoverServices([Self.service]) }

    func centralManager(_ c: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        connected = false; char = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.scan() }
    }

    func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) { scan() }

    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        p.services?.forEach { p.discoverCharacteristics([Self.characteristic], for: $0) }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        guard let c = s.characteristics?.first(where: { $0.uuid == Self.characteristic }) else { return }
        char = c; connected = true
        p.writeValue(Data([lastState]), for: c, type: .withoutResponse)
    }
}
