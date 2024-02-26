import SwiftUI

struct PBAnalogControl: View {
  @StateObject var speedCharacteristic: PBFloatCharacteristic
  @StateObject var angleCharacteristic: PBFloatCharacteristic
  @State private var innerCircleLocation: CGPoint = .zero
  @State var snapAngle: Bool = false
  
  
  func mirrorXAxis(angle: Double) -> Double {
    let twoPi = 2.0 * Double.pi
    let mirrored = twoPi - angle
    return mirrored.truncatingRemainder(dividingBy: twoPi)
  }
  
  func closestValue(to number: Double, in values: [Double]) -> Double? {
    guard !values.isEmpty else { return nil }
    
    var closestValue = values[0]
    var smallestDifference = abs(closestValue - number)
    
    for value in values {
      let difference = abs(value - number)
      if difference < smallestDifference {
        smallestDifference = difference
        closestValue = value
      }
    }
    
    return closestValue
  }
  
  func roundToNearestTenth(_ value: Double) -> Double {
    return (value * 10).rounded() / 10
  }
  
  func getPosition(size: CGSize) -> CGPoint {
    if (innerCircleLocation == .zero) {
      return CGPoint(x: size.width / 2, y: size.height / 2);
    } else {
      return innerCircleLocation;
    }
  }
  
  func fingerDrag(size:CGSize, location: CGPoint) -> some Gesture {
    DragGesture()
      .onChanged { value in
        // Calculate the distance between the finger location and the center of the inner circle
        let angle = atan2(value.location.y - location.y, value.location.x - location.x)
        let snappedAngle = closestValue(to: angle, in: [-3.14, -1.57, 0.0, 1.57, 3.14]) ?? 0
        let drawAngle = snapAngle ? snappedAngle : roundToNearestTenth(angle);
        let adjustedAngle = mirrorXAxis(angle: drawAngle);
        
        let distance = sqrt(pow(value.location.x - location.x, 2) + pow(value.location.y - location.y, 2))
        let maxDistance = (min(size.width, size.height) / 2) - 45
        let clampedDistance = min(distance, maxDistance)
        let scaledDistance = clampedDistance.converting(from: 0.0...maxDistance, to:0.0...1.0)
        let newX = location.x + cos(drawAngle) * clampedDistance
        let newY = location.y + sin(drawAngle) * clampedDistance
        
        angleCharacteristic.currentValue = Float(adjustedAngle)
        speedCharacteristic.currentValue = Float(scaledDistance)
        innerCircleLocation = CGPoint(x: newX, y: newY)
      }
      .onEnded { value in
        // Snap the smaller circle to the center of the larger circle
        let center = location
        innerCircleLocation = center
        speedCharacteristic.currentValue = 0.0
        angleCharacteristic.currentValue = 0.0
      }
  }
  
  var body: some View {
    VStack() {
      Toggle(isOn: $snapAngle) {
        Text("Clamp Angle")
      }.padding()
      GeometryReader { geometry in
        ZStack() {
          Circle()
            .foregroundColor(Color(red: 217 / 255, green: 214 / 255, blue: 212 / 255))
            .frame(
              width: min(geometry.size.width, geometry.size.height),
              height: min(geometry.size.width, geometry.size.height))
          Circle()
            .foregroundColor(Color(red: 30 / 255, green: 40 / 255, blue: 45 / 255))
            .frame(width: 90, height: 90)
            .position(getPosition(size: geometry.size))
            .gesture(fingerDrag(size: geometry.size, location: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)))
          if snapAngle {
            let radius = min(geometry.size.width, geometry.size.height)
            Path { path in
              path.move(to: CGPoint(x: geometry.size.width / 2, y: (geometry.size.height / 2) - (radius / 2)))
              path.addLine(to: CGPoint(x: geometry.size.width / 2, y: (geometry.size.height / 2 ) + (radius / 2)))
              path.move(to: CGPoint(x: geometry.size.width / 2 - radius / 2, y: geometry.size.height / 2))
              path.addLine(to: CGPoint(x: geometry.size.width / 2 + radius / 2, y: geometry.size.height / 2))
            }.stroke(Color(red: 30 / 255, green: 40 / 255, blue: 45 / 255), lineWidth: 5)
          }
        }
      }
    }
  }
}
