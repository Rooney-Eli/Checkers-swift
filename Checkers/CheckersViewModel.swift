import Foundation



class CheckersViewModel: ObservableObject {
    @Published var board = Board().initialize()
    
    func onPieceTapped(piece: Piece) -> [Action] {
        let captures = board.getChainCaptures(piece)
        if !captures.isEmpty { return captures.map { Action.chainCapture($0) } }
        
        let moves = board.getMoves(piece)
        if !moves.isEmpty { return moves.map { Action.move($0) } }
        
        return []
    }
    
}
