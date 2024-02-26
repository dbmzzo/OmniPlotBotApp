import SwiftUI

struct PBSlideControl: View {
  @StateObject var characteristic: PBFloatCharacteristic
  @State private var isDragging: Bool = false
  
  var body: some View {
    Slider(value: $characteristic.currentValue, in: -1...1, onEditingChanged: { editing in
      if !editing && isDragging {
        characteristic.currentValue = 0;
      }
      isDragging = editing
    })
  }
}

