import SwiftUI

struct PBToggle: View {
  @ObservedObject var characteristic: PBIntCharacteristic
  var body: some View {
    Toggle(
      isOn: Binding(
        get: { characteristic.currentValue == 1 },
        set: { newValue in characteristic.currentValue = newValue ? 1 : 0 }
      )
    ) {
      Text("Pen")
    }.padding()
  }
}

