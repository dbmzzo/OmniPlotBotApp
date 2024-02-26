import Foundation

extension FloatingPoint {
  func converting(from input: ClosedRange<Self>, to output: ClosedRange<Self>) -> Self {
    let x = (output.upperBound - output.lowerBound) * (self - input.lowerBound)
    let y = (input.upperBound - input.lowerBound)
    return x / y + output.lowerBound
  }
}

extension BinaryInteger {
    func converting(from input: ClosedRange<Self>, to output: ClosedRange<Self>) -> Self {
        let x = (output.upperBound - output.lowerBound) * (self - input.lowerBound)
        let y = (input.upperBound - input.lowerBound)
        return x / y + output.lowerBound
    }
}
