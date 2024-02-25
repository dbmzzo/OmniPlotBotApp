import Foundation
import CoreBluetooth

func getCharacteristics(fromPeripheral: CBPeripheral) -> [any PBCharacteristicProtocol] {
      if let services = fromPeripheral.services {
        return services.flatMap({
          return $0.characteristics?.map({ characteristic in
            switch(characteristic.uuid.uuidString.lowercased()) {
            case "bbbf63c9-abf0-4344-aa50-7416e3487091":
              return PBStringCharacteristic(characteristic, peripheral: fromPeripheral)
            case "930b5db3-a406-4a44-b9aa-666165e31b1e":
              return PBIntCharacteristic(characteristic, peripheral: fromPeripheral)
            case "40447395-2f51-48d3-95a6-9856424460f4":
              return PBIntCharacteristic(characteristic, peripheral: fromPeripheral)
            default:
              return PBFloatCharacteristic(characteristic, peripheral: fromPeripheral)
            }
          }) ?? []
        })
      } else {
        return []
      }
  }


class PBPeripheral: NSObject, ObservableObject {
  @Published var name:String
  @Published var peripheral:CBPeripheral
  @Published var advertisementData:[String: Any]
  @Published var characteristics:[any PBCharacteristicProtocol]
  
  func updateCharacteristics() {
    characteristics = getCharacteristics(fromPeripheral: peripheral)
    self.objectWillChange.send()
  }
  
  func updateCharacteristicValues() {
    characteristics.forEach({ characteristic in
      characteristic.updateValue()
    })
    self.objectWillChange.send()
  }
  
  var speedCharacteristic: (any PBCharacteristicProtocol)? {
    get {
      let characteristic = characteristics.first { characteristic in
        if characteristic.name == "Speed" {
          return true
        }
        return false
      }
      return characteristic
    }
  }
  
  var angleCharacteristic: (any PBCharacteristicProtocol)? {
    get {
      let characteristic = characteristics.first { characteristic in
        if characteristic.name == "Direction" {
          return true
        }
        return false
      }
      return characteristic
    }
  }
  
  var velocityCharacteristics: [any PBCharacteristicProtocol] {
    get {
      let velocityChars = characteristics.filter { characteristic in
        return characteristic.name == "Speed" || characteristic.name == "Direction"
      }
      return velocityChars
    }
  }
  
  var rotationCharacteristic: (any PBCharacteristicProtocol)? {
    get {
      return characteristics.first { characteristic in
        return characteristic.name == "Rotation"
      }
    }
  }
  
  init(withName name:String, withPeripheral peripheral: CBPeripheral, withAdvertisementData advertisementData:[String:Any]) {
    self.name = name
    self.peripheral = peripheral
    self.advertisementData = advertisementData
    self.characteristics = getCharacteristics(fromPeripheral: peripheral)
    super.init()
  }
}

