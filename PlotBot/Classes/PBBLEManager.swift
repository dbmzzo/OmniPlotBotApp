import Foundation
import CoreBluetooth

class RPBLEManager: NSObject, ObservableObject {
  var centralManager: CBCentralManager!
  @Published var isSwitchedOn = false
  @Published var isScanning = false
  @Published var isConnected = false
  @Published var discoveredDevices:[PBPeripheral] = []
  @Published var connectedDevices:[PBPeripheral] = []
  @Published var joystickReady = false
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
      isSwitchedOn = true
      startScanning()
      break
    default:
      isSwitchedOn = false
      stopScanning()
      break
    }
  }
  
  func startScanning() {
    print("Started Scanning")
    isScanning = true
    centralManager.scanForPeripherals(withServices: [PBServiceUUID], options: nil)
  }
  
  func stopScanning() {
    print("Stopped Scanning")
    isScanning = false
    centralManager.stopScan()
  }
  
  func connectPeripheral(peripheral:CBPeripheral) {
    centralManager.connect(peripheral, options: nil)
    peripheral.delegate = self
    self.stopScanning()
  }
  
  func characteristicName(uuid: CBUUID) -> String {
      if let matchingCharacteristic = self.discoveredDevices
          .flatMap({ $0.characteristics })
          .first(where: { char in
              return char.characteristic.uuid == uuid
          }) {
          
          switch matchingCharacteristic {
          case let floatChar:
              return floatChar.name
          }
      }
      
      return "Unnamed"
  }
  
  func hasJoystickChars() -> Bool {
    var hasSpeed = false
    var hasAngle = false
    var hasRotation = false
    
    let characteristics = discoveredDevices.flatMap({$0.characteristics});
    characteristics.forEach({ characteristic in
      switch characteristic.characteristic.uuid.uuidString.lowercased() {
      case "bcdf77f1-7b10-41fa-9ed5-83bc69fd3fde":
        hasSpeed = characteristic.name == "Speed"
        break
      case "7621b66b-10ee-4172-b3bf-dad42cd5972d":
        hasRotation = characteristic.name == "Rotation"
        break
      case "a393436b-8be0-4280-bff8-b357bf1e30c7":
        hasAngle = characteristic.name == "Direction"
        break
      default:
        break
      }
    })
    return hasSpeed && hasAngle && hasRotation;
  }
  
  override init() {
    super.init()
    centralManager = CBCentralManager(delegate:self, queue: nil)
    centralManager.delegate = self
  }

  
}

extension RPBLEManager: CBCentralManagerDelegate {
  
  // Discovered PERIPHERAL
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    if !discoveredDevices.contains(where: {existingPeripheral in
      existingPeripheral.peripheral.identifier.uuidString == peripheral.identifier.uuidString
    }) {
      if let name = advertisementData[CBAdvertisementDataLocalNameKey] {
        peripheral.delegate = self
        let newDevice = PBPeripheral(withName: name as! String, withPeripheral: peripheral, withAdvertisementData: advertisementData)
        discoveredDevices.append(newDevice)
        self.connectPeripheral(peripheral: peripheral);
      }
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    connectedDevices.removeAll(where: {
      $0.peripheral.identifier.uuidString == peripheral.identifier.uuidString;
    })
    self.connectedDevices = self.connectedDevices.filter {$0.peripheral.identifier.uuidString == peripheral.identifier.uuidString};
      discoveredDevices.removeAll(where: {
        $0.peripheral.identifier.uuidString == peripheral.identifier.uuidString;
      })
    centralManager.scanForPeripherals(withServices: [PBServiceUUID], options: nil)
  }
  
  // Connected to PERIPHERAL
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    if let matchingDevice = discoveredDevices.first(where: {
      return $0.peripheral.identifier.uuidString == peripheral.identifier.uuidString
    }) {
      self.connectedDevices.append(matchingDevice)
      peripheral.discoverServices([PBServiceUUID])
    }
  }
  
}

extension RPBLEManager: CBPeripheralDelegate {
  // Discovered services
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
      print("Error discovering services: %s", error.localizedDescription)
      return
    }
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    guard let peripheralServices = peripheral.services else { return }
    for service in peripheralServices {
      peripheral.discoverCharacteristics(nil, for: service)
    }
    self.objectWillChange.send()
  }
  
  // Discovered characteristics
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristics = service.characteristics else { return }
    for characteristic in characteristics {
      peripheral.setNotifyValue(true, for: characteristic)
      peripheral.readValue(for: characteristic)
      peripheral.discoverDescriptors(for: characteristic)
    }
    discoveredDevices.forEach { device in
      device.updateCharacteristics()
    }
    self.objectWillChange.send()
  }
  
  // Updated descriptor value
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    // Get and print user description for a given characteristic
    self.joystickReady = hasJoystickChars()
    self.objectWillChange.send()
  }
  
  // Discovered descriptors
  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    // print("discovered descriptors")
    guard let descriptors = characteristic.descriptors else { return }
    for descriptor in descriptors {
      peripheral.readValue(for: descriptor);
    }
  }
  
  // Updated characteristic value
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    discoveredDevices.forEach { device in
      device.updateCharacteristicValues()
    }
    self.objectWillChange.send()
  }
  
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    if let error = error {
      print(error)
      return
    }
    self.objectWillChange.send()
  }
}
