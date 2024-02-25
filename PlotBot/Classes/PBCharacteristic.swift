import Foundation
import CoreBluetooth

protocol PBCharacteristicProtocol: ObservableObject {
    var characteristic: CBCharacteristic { get set }
    var peripheral: CBPeripheral { get set }
    var name: String { get }
    var dataType: String { get }
    func updateValue()
    init(_ characteristic: CBCharacteristic, peripheral: CBPeripheral)
}

class PBFloatCharacteristic: PBCharacteristicProtocol {
  @Published var characteristic: CBCharacteristic
  @Published var peripheral: CBPeripheral
  @Published var value: Float
  
  var currentValue: Float {
    get {
      return self.value
    }
    set(newValue) {
      if (newValue != self.value) {
        self.value = newValue
        let dataValue = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        peripheral.writeValue(dataValue, for: characteristic, type: .withoutResponse)
        self.objectWillChange.send()
      }
    }
  }
  
  func updateValue() {
    self.value = characteristic.value?.withUnsafeBytes { $0.load(as: Float.self) } ?? 0
  }

  required init(_ characteristic: CBCharacteristic, peripheral: CBPeripheral) {
    self.value = characteristic.value?.withUnsafeBytes { $0.load(as: Float.self) } ?? 0
    self.peripheral = peripheral
    self.characteristic = characteristic
  }
  
}

class PBStringCharacteristic: PBCharacteristicProtocol {
  @Published var characteristic: CBCharacteristic
  @Published var peripheral: CBPeripheral
  @Published var value: String
  
  var currentValue: String {
    get {
      return self.value
    }
    set(newValue) {
      self.value = newValue
      if let dataValue = newValue.data(using: .utf8) {
        peripheral.writeValue(dataValue, for: characteristic, type: .withResponse)
      }
      self.objectWillChange.send()
    }
  }
  
  func updateValue() {
    if let charValue = characteristic.value {
      if let stringValue = String(data: charValue, encoding: .utf8) {
        self.value = stringValue
      } else {
        self.value = "NONE"
      }
    } else {
      self.value = "NONE"
    }
  }

  required init(_ characteristic: CBCharacteristic, peripheral: CBPeripheral) {
    if let charValue = characteristic.value {
      if let stringValue = String(data: charValue, encoding: .utf8) {
        self.value = stringValue
      } else {
        self.value = "NONE"
      }
    } else {
      self.value = "NONE"
    }
    self.characteristic = characteristic
    self.peripheral = peripheral
  }
  
}

class PBIntCharacteristic: PBCharacteristicProtocol {
  @Published var characteristic: CBCharacteristic
  @Published var peripheral: CBPeripheral
  @Published var value: Int
  
  var currentValue: Int {
    get {
      return self.value
    }
    set(newValue) {
      self.value = newValue
      let dataValue = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
      peripheral.writeValue(dataValue, for: characteristic, type: .withoutResponse)
      self.objectWillChange.send()
    }
  }
  
  func updateValue() {
    self.value = Int((characteristic.value?.withUnsafeBytes {
      $0.load(as: Int32.self)
    }) ?? 0)
  }

  required init(_ characteristic: CBCharacteristic, peripheral: CBPeripheral) {
    self.value = Int((characteristic.value?.withUnsafeBytes {
      $0.load(as: Int32.self)
    }) ?? 0)
    self.peripheral = peripheral
    self.characteristic = characteristic
  }
}

extension PBCharacteristicProtocol {
  var name: String {
    get {
      let notFound = "(Unnamed)"
      guard let descriptors = characteristic.descriptors else { return notFound }
      if let descriptor = descriptors.first(where: {
        return $0.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString
      }) {
        return descriptor.value as? String ?? notFound
      }
      return notFound
    }
  }
  
  var dataType: String {
    get {
      let notFound = "(None)"
      guard let descriptors = characteristic.descriptors else { return notFound }
      if let descriptor = descriptors.first(where: {
        return $0.uuid.uuidString == PBCharDataTypeUUID.uuidString
      }) {
        if ((descriptor.value != nil) && descriptor.uuid.uuidString == PBCharDataTypeUUID.uuidString) {
          let type = String(decoding: (descriptor.value as? Data)!, as: UTF8.self);
          if (!type.isEmpty) {
            return type
          }
        }
      }
      return notFound
    }
  }
  
}
