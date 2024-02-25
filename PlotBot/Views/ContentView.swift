import SwiftUI
import CoreBluetooth

struct ControlView: View {
  @StateObject var device: PBPeripheral
  var body: some View {
    VStack {
      if let speedValue = device.speedCharacteristic, let angleValue = device.angleCharacteristic {
        PBAnalogControl(speedCharacteristic: speedValue as! PBFloatCharacteristic, angleCharacteristic: angleValue as! PBFloatCharacteristic);
      }
      if let rotationValue = device.rotationCharacteristic {
        PBSlideControl(characteristic: rotationValue as! PBFloatCharacteristic);
      }
    }
  }
}

struct DevicesList: View {
  @ObservedObject var bleManager: RPBLEManager
  
  var body: some View {
    NavigationView() {
      List(bleManager.discoveredDevices, id: \.self) { device in
        VStack() {
          if bleManager.connectedDevices.contains(device) {
            NavigationLink(device.name, destination: ControlView(device: device))
          } else {
            Button(device.name) {
              bleManager.connectPeripheral(peripheral: device.peripheral)
            }
          }
        }
      }.navigationTitle("Devices")
    }.frame(maxHeight: .infinity).navigationViewStyle(.stack)
  }
}


struct ContentView: View {
  @ObservedObject var bleManager:RPBLEManager
  var body: some View {
    DevicesList(bleManager: bleManager)
  }
}

struct ListHeader: View {
  var body: some View {
    HStack {
      Image(systemName: "antenna.radiowaves.left.and.right.circle.fill").foregroundColor(.green)
      Text("Select a device")
    }
  }
}

struct ListFooter: View {
  var body: some View {
    Text("")
  }
}
