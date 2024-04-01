import Foundation

enum Action {
    case capture(Capture)
    case chainCapture(ChainCapture)
    case move(Move)
    
    struct Capture : Hashable {
        let origin: Int
        let capturedPosition: Int
        let destination: Int
    }
    
    struct ChainCapture {
        let captures: [Capture]
    }
    
    struct Move {
        let origin: Int
        let destination: Int
    }
}
