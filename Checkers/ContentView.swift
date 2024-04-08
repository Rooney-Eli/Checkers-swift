import SwiftUI


struct ContentView: View {
    @ObservedObject var viewModel = CheckersViewModel()
    @State private var squares: [[Square?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    @State private var tappedSquare: Square? = nil
    @State private var selectedAction: ActionSelection? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                ForEach(0..<8) { y in
                    GridRow {
                        ForEach(0..<8) { x in
                            squares[y][x].frame(width: size/8, height: size/8)
                        }
                    }
                }
            }
        }
        .onAppear {
            self.initializeSquares() // Initialize squares when the view appears
        }
    }
    
    func initializeSquares() {
        var squaresArray: [[Square?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        var positionCounter = 0
        for y in 0..<8 {
            for x in 0..<8 {
                if y % 2 != 0 {
                    if x % 2 == 0 {
                        squaresArray[y][x] = Square(
                            x: x,
                            y: y,
                            position: positionCounter,
                            color: .black,
                            piece: viewModel.board.pieces.first { $0.position == positionCounter },
                            onTap: self.handleSquareTap
                        )
                        positionCounter += 1
                    } else {
                        squaresArray[y][x] = Square(
                            x: x,
                            y: y,
                            position: -1,
                            color: .red,
                            piece: nil,
                            onTap: self.handleSquareTap
                        )
                    }
                } else {
                    if x % 2 != 0 {
                        squaresArray[y][x] = Square(
                            x: x,
                            y: y,
                            position: positionCounter,
                            color: .black,
                            piece: viewModel.board.pieces.first { $0.position == positionCounter },
                            onTap: self.handleSquareTap
                        )
                        positionCounter += 1
                    } else {
                        squaresArray[y][x] = Square(
                            x: x,
                            y: y,
                            position: -1,
                            color: .red,
                            piece: nil,
                            onTap: self.handleSquareTap
                        )
                    }
                }
            }
        }
        self.squares = squaresArray
    }
    
    func highlightSquares(_ positions: [Int]) {
        for y in 0..<squares.count {
            for x in 0..<squares[y].count {
                if let square = squares[y][x], positions.contains(square.position) {
                    squares[y][x] = Square(
                        x: square.x,
                        y: square.y,
                        position: square.position,
                        color: square.color,
                        piece: square.piece,
                        onTap: self.handleSquareTap,
                        isHighlighted: !square.isHighlighted
                    )
                }
            }
        }
    }
    
    func unhighlightSquares() {
        squares.forEach { row in
            row.forEach { square in
                guard let square = square else { return }
                squares[square.y][square.x] = Square(
                    x: square.x,
                    y: square.y,
                    position: square.position,
                    color: square.color,
                    piece: square.piece,
                    onTap: self.handleSquareTap,
                    isHighlighted: false
                )
            }
        }
    }
    
    func handleSquareTap(_ x: Int, _ y: Int, _ piece: Piece?) {
        print("handleSquareTap: Square tapped at position \(x) \(y)")
        
        if let sq = squares[y][x] {
            if let p = piece {
                let actions = viewModel.onPieceTapped(piece: p)
                print("handleSquareTap: \(actions)")
                
                let nextAction: Action?
                if(!actions.isEmpty) {
                    if selectedAction?.piece.position != p.position {
                        selectedAction = ActionSelection(actions: actions, piece: p)
                        nextAction = selectedAction?.actions[0]
                    } else {
                        nextAction = selectedAction?.nextAction()
                    }
                } else {
                    nextAction = nil
                }
                
                let destinations: [Int]
                switch nextAction {
                case .capture(let capture):
                    destinations = [capture.destination]
                case .chainCapture(let chainCapture):
                    destinations = chainCapture.captures.map { $0.destination }
                case .move(let move):
                    destinations = [move.destination]
                default:
                    destinations = []
                }
                unhighlightSquares()
                highlightSquares(destinations + [p.position])
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




struct Square : View, Identifiable {
    let id: Int
    let x: Int
    let y: Int
    let position: Int
    let color: Color
    var piece: Piece?
    let onTap: (Int, Int, Piece?) -> Void
    let isHighlighted: Bool
 
    var body: some View {
        Rectangle()
            .fill(color)
            .overlay(
                ZStack {
                    piece != nil ? Circle().fill(piece?.team == Piece.Team.red ? Color.red : Color.gray).frame(width: 30, height: 30) : nil
                    Text("\(position)").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                }
                
            ).onTapGesture {
                onTap(x, y, piece)
            }.border(
                isHighlighted ? Color.green : Color.blue, width: isHighlighted ? 3 : 1
            )
    }
    
    init(
        x: Int,
        y: Int,
        position: Int,
        color: Color,
        piece: Piece?,
        onTap: @escaping (Int, Int, Piece?) -> Void,
        isHighlighted: Bool = false
    ) {
        self.id = position
        self.position = position
        self.x = x
        self.y = y
        self.color = color
        self.piece = piece
        self.onTap = onTap
        self.isHighlighted = isHighlighted
     }

}

struct ActionSelection {
    let actions: [Action]
    var index: Int = 0
    let piece: Piece
    
    init(actions: [Action], piece: Piece) {
        self.actions = actions
        self.piece = piece
    }
    
    mutating func nextAction() -> Action {
        if actions.count == 1 { return actions[index] }
    
        if index == actions.count - 1 {
            index = 0
        } else {
            index += 1
        }
        
        return actions[index]
        
    }
}
