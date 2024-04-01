import Foundation

struct Piece: Hashable {
    enum Team { case red, black }
    let position: Int
    let team: Team
    let isKing: Bool
}
