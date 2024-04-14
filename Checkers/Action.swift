import Foundation

enum Action {
    case capture(Capture) // Capturing opponents piece
    case chainCapture(ChainCapture)
    case move(Move)
    
    struct Capture : Hashable {
        let origin: Int
        let capturedPosition: Int
        let destination: Int
    }
    
    struct ChainCapture {
        let captures: [Capture] // array of captures
    }
    
    struct Move {
        let origin: Int
        let destination: Int
    }
}
