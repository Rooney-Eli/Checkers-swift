import Foundation

struct Board {
    var pieces: [Piece]
    
    init(_ pieces: [Piece] = []) {
        self.pieces = pieces
    }
    
    func initialize() -> Board {
        let redStartPositions = 0 ..< ((8 / 2) * 3) // Range 0 - 11
        let blackStartPositions = (((8 * 8) / 2) - ((8 / 2) * 3)) ..< ((8 * 8) / 2) //Range 20 to 31
        
        // array of Red Piece objects, mapped to their starting positions
        let redPieces = redStartPositions.map { position in Piece(position: position, team: Piece.Team.red, isKing: false) }
        // array of Black Piece objects, mapped to their starting positions
        let blackPieces = blackStartPositions.map { position in Piece(position: position, team: Piece.Team.black, isKing: false) }
        
        //todo remove this
        let testPiece = [Piece(position: 16, team: Piece.Team.red, isKing: false)]
        
        let initialPieces = redPieces + blackPieces + testPiece
        
        return Board(initialPieces)
    }
    
    /**
     Updates the game board after a single capture occurs
     - Parameters:
        - capture: An 'Action.Capture' instance'
        - pieces: array of pieces currently represented on board
     - returns: an updated game board after a single capture
     */
    func capturePiece(_ capture: Action.Capture, _ pieces: [Piece]) -> Board  {
        //
        guard let actingPiece = pieces.first(where: { $0.position == capture.origin }) else {
            fatalError("Piece not found at origin position \(capture.origin)")
        }
        
        // Filters out the moving piece and the piece it is capturing
        let remainingPieces = pieces.filter { $0.position != capture.origin && $0.position != capture.capturedPosition }
        
        // A board is returned after updating pieces' positions
        return Board(
            remainingPieces + [Piece( //combines remaining pieces(idle) with the recently moved piece
                position: capture.destination, //piece position after making a capture
                team: actingPiece.team,
                //determines if piece is a king now in its new position
                isKing: !actingPiece.isKing ? inKingmakerRow(capture.destination, actingPiece.team) : true
            )]
        )
    }
    
    /**
     Updates the board after a sequence of captures (chain capture)
     - Parameters:
        - chainCapture: An "Action.ChainCapture" instance
        - pieces: array of pieces currently represented on board
     - returns: an updated game board after a chain capture occurs
     */
    func capturePieces(_ chainCapture: Action.ChainCapture, _ pieces: [Piece]) -> Board {
        guard let firstCapture = chainCapture.captures.first else { //ensures chain capture has atleast one capture
            fatalError("First capture was not found for chain capture")
        }
        
        guard let actingPiece = pieces.first(where: { $0.position == firstCapture.origin }) else { //finds capturer
            fatalError("Piece not found at origin position \(firstCapture.origin)")
        }
        
        guard let lastCapture = chainCapture.captures.last else { //finding last capture in the chain
            fatalError("Last capture was not found for chain capture")
        }
        
        let capturedPositions = Set(chainCapture.captures.map { $0.capturedPosition }) // (set of ints) extract positions of captured pieces
        let finalDestination = lastCapture.destination // final position of acting piece after chain capture
        
        // array that filters out the captured pieces and acting piece
        let remainingPieces = pieces.filter { !capturedPositions.contains($0.position) && $0.position != actingPiece.position }
        
        // Bool that represents if the action piece visited row that would make it a King
        let visitsKingsRow = chainCapture.captures.first { inKingmakerRow($0.destination, actingPiece.team) } != nil
        
        // returns updated board with the idle pieces and action piece.
        return Board(
            remainingPieces + [Piece(
                position: finalDestination,
                team: actingPiece.team,
                isKing: actingPiece.isKing ? true : visitsKingsRow
            )]
        )
    }
    
    /**
     Move a piece on board
     - Parameters:
        - move: An 'Action.Move' instance
        - pieces: array of pieces currently on the board
     - returns: an updated game board after a piece is moved
     */
    func movePiece(_ move: Action.Move, _ pieces: [Piece]) -> Board {
        // Map over the pieces to update the position of the moved piece
        let updatedPieces = pieces.map { piece in
            if piece.position == move.origin {
                return Piece(
                    position: move.destination,
                    team: piece.team,
                    isKing: piece.isKing
                )
            } else {
                return piece
            }
        }
        
        // Return the updated board state
        return Board(updatedPieces)
    }

    
    /**
     Checks if a piece is in a Kingmaker row
     - Parameters:
        - position: The position of the piece on the board
        - team: Team color of piece
     - Returns: True if Red team is in the bottom row or if Black Team is in the top row; False otherwise
     */
    private func inKingmakerRow(_ position: Int, _ team: Piece.Team) -> Bool {
        switch team {
            case .red:
                return !boardExistsDownOne(position)
            case .black:
                return !boardExistsUpOne(position)
        }
    }
    
    /**
     Performs an intermediate capture during a chain capture
     - Parameters:
        - capture: Capture action
        - pieces: array of Pieces on board
     - Returns: updated board following intermediate capture
     */
    private func intermediateCapture(_ capture: Action.Capture, _ pieces: [Piece]) -> Board {
        guard let actingPiece = pieces.first(where: { $0.position == capture.origin }) else {
            fatalError("Piece not found at origin position \(capture.origin)")
        }
        
        // makes array with captured and acting pieces filtered out
        let remainingPieces = pieces.filter { $0.position != capture.origin && $0.position != capture.capturedPosition }
        
        return Board(remainingPieces + [Piece(
            position: capture.destination,
            team: actingPiece.team,
            isKing: actingPiece.isKing
        )])
    }
    /**
     Recursively retrieves all possible chain captures for a given checker piece
     - Parameters:
        - piece: The checker piece being analyzed
        - pieces: Array of all pieces currently on board
        - currentBranch: ll
     - returns: captured pieces that were captured in a chain
     */
    private func getPieceChainCaptures(
        _ piece: Piece,
        _ pieces: [Piece],
        _ currentBranch: Action.ChainCapture = Action.ChainCapture(captures: [])
    ) -> [Action.ChainCapture] {
        let captures: [Action.Capture] = getPieceCaptures(piece, pieces)
        
        // If no captures available, return the current chain capture sequence
        if(captures.isEmpty) { return [currentBranch] }
        
        return captures.flatMap { capture in
            let resultingBoard = intermediateCapture(capture, pieces)
            
            guard let movedPiece = pieces.first(where: { $0.position == capture.origin }) else {
                fatalError("Piece not found at origin position \(capture.origin)")
            }
            
            return getPieceChainCaptures(
                movedPiece,
                resultingBoard.pieces,
                Action.ChainCapture(captures: currentBranch.captures + [capture])
            )
            
            
        }
        
    }
    
    
    private func getPieceCaptures(
        _ piece: Piece,
        _ pieces: [Piece]
    ) -> [Action.Capture] {
        let (start, end): (Int, Int)
        switch piece.team {
            case .red:
                start = piece.isKing ? 0 : 2
                end = piece.isKing ? 3 : 3
                
            case .black:
                start = piece.isKing ? 0 : 0
                end = piece.isKing ? 3 : 1
        }
        
        let captureSuite: [CaptureFunctionSuite] = [
            CaptureFunctionSuite(
                boardExistsTwoInDirection: self.boardExistsTwoDiagonalUpRight,
                positionInDirection: self.positionOneDiagonalUpRight,
                positionTwoDiagonalInDirection: self.positionTwoDiagonalUpRight
            ),
            CaptureFunctionSuite(
                boardExistsTwoInDirection: self.boardExistsTwoDiagonalUpLeft,
                positionInDirection: self.positionOneDiagonalUpLeft,
                positionTwoDiagonalInDirection: self.positionTwoDiagonalUpLeft
            ),
            CaptureFunctionSuite(
                boardExistsTwoInDirection: self.boardExistsTwoDiagonalDownRight,
                positionInDirection: self.positionOneDiagonalDownRight,
                positionTwoDiagonalInDirection: self.positionTwoDiagonalDownRight
            ),
            CaptureFunctionSuite(
                boardExistsTwoInDirection: self.boardExistsTwoDiagonalDownLeft,
                positionInDirection: self.positionOneDiagonalDownLeft,
                positionTwoDiagonalInDirection: self.positionTwoDiagonalDownLeft
            )
        ]
        
        let capturablePositions = (start...end).enumerated().compactMap {
            checkPieceCanCaptureDirection(
                piece,
                pieces,
                captureSuite[$0.offset].positionOneDiagonalInDirection,
                captureSuite[$0.offset].positionTwoDiagonalInDirection,
                captureSuite[$0.offset].boardExistsTwoInDirection
            )
        }
        
        return capturablePositions
    }
    
    /**
     Retrieves the possible capture options for a given piece on the board
     - Parameters:
        - piece: The piece for which to determine capture actions
        - pieces: The array of pieces currently on the board
     - returns: Possible capture actions as an array of 'Action.Capture' instances
     */
    private func getPieceMoves(
        _ piece: Piece,
        _ pieces: [Piece]
    ) -> [Action.Move] {
        let (start, end): (Int, Int)
        switch piece.team {
            case .red:
                start = piece.isKing ? 0 : 2
                end = piece.isKing ? 3 : 3
                
            case .black:
                start = piece.isKing ? 0 : 0
                end = piece.isKing ? 3 : 1
        }
         
        let moveSuite: [MoveFunctionSuite] = [
            MoveFunctionSuite(
                boardExistsInDirection: self.boardExistsOneDiagonalUpRight,
                positionOneDiagonalInDirection: self.positionOneDiagonalUpRight
            ),
            MoveFunctionSuite(
                boardExistsInDirection: self.boardExistsOneDiagonalUpLeft,
                positionOneDiagonalInDirection: self.positionOneDiagonalUpLeft
            ),
            MoveFunctionSuite(
                boardExistsInDirection: self.boardExistsOneDiagonalDownRight,
                positionOneDiagonalInDirection: self.positionOneDiagonalDownRight
            ),
            MoveFunctionSuite(
                boardExistsInDirection: self.boardExistsOneDiagonalDownLeft,
                positionOneDiagonalInDirection: self.positionOneDiagonalDownLeft
            )
        ]
        

        let movablePositions = (start...end).enumerated().compactMap {
            checkPieceCanMoveDirection(
                piece,
                pieces,
                moveSuite[$0.offset + start].boardExistsInDirection,
                moveSuite[$0.offset + start].positionOneDiagonalInDirection
            )
        }
        
        return movablePositions
    }
    
    /**
     Checks if a piece can perform a capture in a specific direction on the game board
     - Parameters:
        - piece: The piece attempting to make a capture
        - pieces: pieces on the game board (array)
        - positionInCaptureSpotFunc: A function that calculated the position where the piece would capture another
        - positionTwoDiagonalInDirectionFunc: A function that calculates the second diagonal position after the capture
        - boardExistsTwoDiagonalInDirectionFunc: A function that checks if the board exists two position diagonally in specified directions
     - returns: capture action if possible
     */
    func checkPieceCanCaptureDirection(
        _ piece: Piece,
        _ pieces: [Piece],
        _ positionInCaptureSpotFunc: (Int) -> Int,
        _ positionTwoDiagonalInDirectionFunc: (Int) -> Int,
        _ boardExistsTwoDiagonalInDirectionFunc: (Int) -> Bool
    ) -> Action.Capture? {
        if (!boardExistsTwoDiagonalInDirectionFunc(piece.position)) { return nil }
        
        guard let capturedPiece = pieces.first(where: {
            $0.position == positionInCaptureSpotFunc(piece.position) &&
            $0.team != piece.team &&
            !isPieceInPosition(positionTwoDiagonalInDirectionFunc(piece.position), pieces)
        }) else {
            return nil
        }
        
        return Action.Capture(
            origin: piece.position,
            capturedPosition: capturedPiece.position,
            destination: positionTwoDiagonalInDirectionFunc(piece.position)
        )
    }
    
    /**
    Checks if a piece can perform a move action in a specific direction on the board
     - Parameters:
        - piece: The piece attempting to perform the move action
        - pieces: The pieces currently on the board
        - boardExistsInDirectionFunc: A function that chekcs if the board exists in the specified direction
        - positionOneDiagonalInDirectionFun:
     - returns: Move action if possible
     */
    func checkPieceCanMoveDirection(
        _ piece: Piece,
        _ pieces: [Piece],
        _ boardExistsInDirectionFunc: (Int) -> Bool,
        _ positionOneDiagonalInDirectionFunc: (Int) -> Int
    ) -> Action.Move? {
        let positionOneDiagonalInDirection = positionOneDiagonalInDirectionFunc(piece.position)
        
        if !(boardExistsInDirectionFunc(piece.position) && !isPieceInPosition(positionOneDiagonalInDirection , pieces)) { return nil }
        
        if (pieces.first { $0.position == positionOneDiagonalInDirection } != nil ) { return nil }
        
        return Action.Move(
            origin: piece.position,
            destination: positionOneDiagonalInDirection
        )
    }
    
    /**
     Check if piece is present at a specific positions
     - Parameters:
        - position: position to check for presence of checker piece
        - pieces: Array of pieces that are on the board
     */
    private func isPieceInPosition(_ position: Int, _ pieces: [Piece]) -> Bool {
        return pieces.first { $0.position == position } != nil
    }
    
    /**
     Performs an action on the game board
     - Parameters:
        - action: The action to be performed
     - returns: Updated board after performing the action
     */
    func performAction(action: Action) -> Board {
        switch action {
        case .capture(let capture):
            print("Performing capture action")
            return capturePiece(capture, pieces)
        case .chainCapture(let chainCapture):
            print("Performing chain capture action")
            return capturePieces(chainCapture, pieces)
        case .move(let move):
            print("Performing move action")
            return movePiece(move, pieces)
        }
    }


    
    // Returns column index from a given position
    func column(_ position: Int) -> Int {
        let mod = position % 8
        let columnIndex: Int
        
        if mod < 4 {
            columnIndex = mod % 2 + 1
        } else {
            columnIndex = (mod - 4) * 2
        }
    
        return columnIndex
    }

    // Returns row index from a given position
    func row(_ position: Int) -> Int { position / (8 / 2) }

    // Checks if board exists two positions left of given 'position'
    func boardExistsLeftTwo(_ position: Int) -> Bool { column(position) > 1 }

    // Check is board exists left of given 'position'
    func boardExistsLeftOne(_ position: Int) -> Bool { row(position) % 2 == 0 || column(position) > 0 }

    // Check is board exists two position left of given 'position'
    func boardExistsRightTwo(_ position: Int) -> Bool { column(position) < ((8 / 2) - 1) }

    // Check is board exists right of given 'position'
    func boardExistsRightOne(_ position: Int) -> Bool { row(position) % 2 == 0 ? column(position) < ((8 / 2) - 1) : true }

    // Check is board exists two positions above given 'position'
    func boardExistsUpTwo(_ position: Int) -> Bool { row(position) > 1 }

    // Checks if a position exists in row above the current position
    func boardExistsUpOne(_ position: Int) -> Bool { row(position) > 0 }

    // Check is board exists two positions below the given 'position'
    func boardExistsDownTwo(_ position: Int) -> Bool { row(position) < (8 - 2) }
    
    // Checks if a position exists in row below the current position
    func boardExistsDownOne(_ position: Int) -> Bool { row(position) < (8 - 1) } 
    
    // Returns position, two spots, diagonally up left of paramter 'position'
    func positionTwoDiagonalUpLeft(_ position: Int) -> Int {
        positionOneDiagonalUpLeft(positionOneDiagonalUpLeft(position))
    }

    // Returns position, two spots, diagonally up right of parameter 'position'
    func positionTwoDiagonalUpRight(_ position: Int) -> Int {
        positionOneDiagonalUpRight(positionOneDiagonalUpRight(position))
    }

    // Returns position, two spots, diagonally down left of parameter 'position'
    func positionTwoDiagonalDownLeft(_ position: Int) -> Int {
        positionOneDiagonalDownLeft(positionOneDiagonalDownLeft(position))
    }

    // Returns position, two spots, diagonally down right of parameter 'position'
    func positionTwoDiagonalDownRight(_ position: Int) -> Int {
        positionOneDiagonalDownRight(positionOneDiagonalDownRight(position))
    }

    // Returns true if a position exists one square diagonally, up left
    func boardExistsOneDiagonalUpLeft(_ position: Int) -> Bool {
        boardExistsUpOne(position) && boardExistsLeftOne(position)
    }

    // Returns true if a position exists one square diagonally, up right
    func boardExistsOneDiagonalUpRight(_ position: Int) -> Bool {
        boardExistsUpOne(position) && boardExistsRightOne(position)
    }

    // Returns true if a position exists one square diagonally, down left
    func boardExistsOneDiagonalDownLeft(_ position: Int) -> Bool {
        boardExistsDownOne(position) && boardExistsLeftOne(position)
    }

    // Returns true if a position exists one square diagonally, down right
    func boardExistsOneDiagonalDownRight(_ position: Int) -> Bool {
        boardExistsDownOne(position) && boardExistsRightOne(position)
    }

    // Returns true if a position exists two squares diagonally, up left
    func boardExistsTwoDiagonalUpLeft(_ position: Int) -> Bool {
        boardExistsUpTwo(position) && boardExistsLeftTwo(position)
    }

    // Returns true if a position exists two squares diagonally, up right
    func boardExistsTwoDiagonalUpRight(_ position: Int) -> Bool {
        boardExistsUpTwo(position) && boardExistsRightTwo(position)
    }

    // Returns true if a position exists two squares diagonally, down left
    func boardExistsTwoDiagonalDownLeft(_ position: Int) -> Bool {
        boardExistsDownTwo(position) && boardExistsLeftTwo(position)
    }

    // Returns true if a position exists two squares diagonally, down right
    func boardExistsTwoDiagonalDownRight(_ position: Int) -> Bool {
        boardExistsDownTwo(position) && boardExistsRightTwo(position)
    }

    // Returns position up left diagonally
    func positionOneDiagonalUpLeft(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position - (8 / 2) : position - (8 / 2) - 1
    }

    // Returns position up right diagonally
    func positionOneDiagonalUpRight(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position - (8 / 2) + 1 : position - (8 / 2)
    }

    // Returns position down left diagonally
    func positionOneDiagonalDownLeft(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position + (8 / 2) : position + (8 / 2) - 1
    }

    // Returns position down right diagonally
    func positionOneDiagonalDownRight(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position + (8 / 2) + 1 : position + (8 / 2)
    }
    

    func getChainCaptures(_ piece: Piece) -> [Action.ChainCapture] {
        getPieceChainCaptures(piece, pieces).filter { !$0.captures.isEmpty }
    }
    
    func getMoves(_ piece: Piece) -> [Action.Move] {
        getPieceMoves(piece, pieces)
    }
    
    /**
     Defines functions used to determine capture possibilities in a specific direction
     */
    struct CaptureFunctionSuite {
        let positionOneDiagonalInDirection: (Int) -> Int
        let boardExistsTwoInDirection: (Int) -> Bool
        let positionTwoDiagonalInDirection: (Int) -> Int
        
        init(
            boardExistsTwoInDirection: @escaping (Int) -> Bool,
            positionInDirection: @escaping (Int) -> Int,
            positionTwoDiagonalInDirection: @escaping (Int) -> Int
        ) {
            self.boardExistsTwoInDirection = boardExistsTwoInDirection
            self.positionOneDiagonalInDirection = positionInDirection
            self.positionTwoDiagonalInDirection = positionTwoDiagonalInDirection
        }
    }
    
    /**
     A struct representing a suite of functions to handle moves in different directions
     */
    struct MoveFunctionSuite {
        let boardExistsInDirection: (Int) -> Bool // Function checks if board exists in a given direction
        let positionOneDiagonalInDirection: (Int) -> Int // Function gets position of one diagonal in given direction
        
        init(
            boardExistsInDirection: @escaping (Int) -> Bool,
            positionOneDiagonalInDirection: @escaping (Int) -> Int
        ) {
            self.boardExistsInDirection = boardExistsInDirection
            self.positionOneDiagonalInDirection = positionOneDiagonalInDirection
        }
    }
    
}
