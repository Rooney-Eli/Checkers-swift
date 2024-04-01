import Foundation

struct Board {
    let pieces: [Piece]
    
    init(_ pieces: [Piece]) {
        self.pieces = pieces
    }
    
    
    func capturePiece(_ capture: Action.Capture, _ pieces: [Piece]) -> Board  {
        guard let actingPiece = pieces.first(where: { $0.position == capture.origin }) else {
            fatalError("Piece not found at origin position \(capture.origin)")
        }
        
        let remainingPieces = pieces.filter { $0.position != capture.origin && $0.position != capture.capturedPosition}
        
        return Board(
            remainingPieces + [Piece(
                position: capture.destination,
                team: actingPiece.team,
                isKing: !actingPiece.isKing ? inKingmakerRow(capture.destination, actingPiece.team) : true
            )]
        )
    }
    
    func capturePieces(_ chainCapture: Action.ChainCapture, _ pieces: [Piece]) -> Board {
        guard let firstCapture = chainCapture.captures.first else {
            fatalError("First capture was not found for chain capture")
        }
        
        guard let actingPiece = pieces.first(where: { $0.position == firstCapture.origin }) else {
            fatalError("Piece not found at origin position \(firstCapture.origin)")
        }
        
        guard let lastCapture = chainCapture.captures.last else {
            fatalError("Last capture was not found for chain capture")
        }
        
        let capturedPositions = Set(chainCapture.captures.map { $0.capturedPosition })
        let finalDestination = lastCapture.destination
        let remainingPieces = pieces.filter { !capturedPositions.contains($0.position) && $0.position != actingPiece.position }
        let visitsKingsRow = chainCapture.captures.first { inKingmakerRow($0.destination, actingPiece.team) } != nil
        
        return Board(
            remainingPieces + [Piece(
                position: finalDestination,
                team: actingPiece.team,
                isKing: actingPiece.isKing ? true : visitsKingsRow
            )]
        )
    }
    
    func movePiece(_ move: Action.Move, _ pieces: [Piece]) -> Board {
        let (piecesAtOrigin, remainingPieces) = pieces.reduce(into: ([Piece](), [Piece]())) { result, piece in
            if piece.position == move.origin {
                result.0.append(piece)
            } else {
                result.1.append(piece)
            }
        }
        
        guard let firstPiece = piecesAtOrigin.first else {
            fatalError("Piece not found at origin position \(move.origin)")
        }
        
        return Board(
            remainingPieces + [Piece(
                position: move.destination,
                team: firstPiece.team,
                isKing: !firstPiece.isKing ? inKingmakerRow(move.destination, firstPiece.team) : true
            )]
        )
    }
    
    private func inKingmakerRow(_ position: Int, _ team: Piece.Team) -> Bool {
        switch team {
            case .red:
                return !boardExistsDownOne(position)
            case .black:
                return !boardExistsUpOne(position)
        }
    }
    
    private func intermediateCapture(_ capture: Action.Capture, _ pieces: [Piece]) -> Board {
        guard let actingPiece = pieces.first(where: { $0.position == capture.origin }) else {
            fatalError("Piece not found at origin position \(capture.origin)")
        }
        
        let remainingPieces = pieces.filter { $0.position != capture.origin && $0.position != capture.capturedPosition }
        
        return Board(remainingPieces + [Piece(
            position: capture.destination,
            team: actingPiece.team,
            isKing: actingPiece.isKing
        )])
    }
    
    private func getPieceChainCaptures(
        _ piece: Piece,
        _ pieces: [Piece],
        _ currentBranch: Action.ChainCapture = Action.ChainCapture(captures: [])
    ) -> [Action.ChainCapture] {
        let captures: [Action.Capture] = getPieceCaptures(piece, pieces)
        
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
                moveSuite[$0.offset].boardExistsInDirection,
                moveSuite[$0.offset].positionOneDiagonalInDirection
            )
        }
        
        return movablePositions
    }
    
    
    
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
    
    
    private func isPieceInPosition(_ position: Int, _ pieces: [Piece]) -> Bool {
        return pieces.first { $0.position == position } != nil
    }
    
    func performAction(action: Action) -> Board {
        switch action {
        case .capture(let capture):
            return capturePiece(capture, pieces)
        case .chainCapture(let chainCapture):
            return capturePieces(chainCapture, pieces)
        case .move(let move):
            return movePiece(move, pieces)
        }
    }
    
    func column(_ position: Int) -> Int { position % (8 / 2) }

    func row(_ position: Int) -> Int { position / (8 / 2) }

    func boardExistsLeftTwo(_ position: Int) -> Bool { column(position) > 0 }

    func boardExistsLeftOne(_ position: Int) -> Bool { row(position) % 2 == 0 || column(position) > 0 }

    func boardExistsRightTwo(_ position: Int) -> Bool { column(position) < ((8 / 2) - 1) }

    func boardExistsRightOne(_ position: Int) -> Bool { row(position) % 2 == 0 ? column(position) < ((8 / 2) - 1) : true }

    func boardExistsUpTwo(_ position: Int) -> Bool { row(position) > 1 }

    func boardExistsUpOne(_ position: Int) -> Bool { row(position) > 0 }

    func boardExistsDownTwo(_ position: Int) -> Bool { row(position) < (8 - 2) }

    func boardExistsDownOne(_ position: Int) -> Bool { row(position) < (8 - 1) }
    
    func positionTwoDiagonalUpLeft(_ position: Int) -> Int {
        positionOneDiagonalUpLeft(positionOneDiagonalUpLeft(position))
    }

    func positionTwoDiagonalUpRight(_ position: Int) -> Int {
        positionOneDiagonalUpRight(positionOneDiagonalUpRight(position))
    }

    func positionTwoDiagonalDownLeft(_ position: Int) -> Int {
        positionOneDiagonalDownLeft(positionOneDiagonalDownLeft(position))
    }

    func positionTwoDiagonalDownRight(_ position: Int) -> Int {
        positionOneDiagonalDownRight(positionOneDiagonalDownRight(position))
    }

    func boardExistsOneDiagonalUpLeft(_ position: Int) -> Bool {
        boardExistsUpOne(position) && boardExistsLeftOne(position)
    }

    func boardExistsOneDiagonalUpRight(_ position: Int) -> Bool {
        boardExistsUpOne(position) && boardExistsRightOne(position)
    }

    func boardExistsOneDiagonalDownLeft(_ position: Int) -> Bool {
        boardExistsDownOne(position) && boardExistsLeftOne(position)
    }

    func boardExistsOneDiagonalDownRight(_ position: Int) -> Bool {
        boardExistsDownOne(position) && boardExistsRightOne(position)
    }

    func boardExistsTwoDiagonalUpLeft(_ position: Int) -> Bool {
        boardExistsUpTwo(position) && boardExistsLeftTwo(position)
    }

    func boardExistsTwoDiagonalUpRight(_ position: Int) -> Bool {
        boardExistsUpTwo(position) && boardExistsRightTwo(position)
    }

    func boardExistsTwoDiagonalDownLeft(_ position: Int) -> Bool {
        boardExistsDownTwo(position) && boardExistsLeftTwo(position)
    }

    func boardExistsTwoDiagonalDownRight(_ position: Int) -> Bool {
        boardExistsDownTwo(position) && boardExistsRightTwo(position)
    }

    func positionOneDiagonalUpLeft(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position - (8 / 2) : position - (8 / 2) - 1
    }

    func positionOneDiagonalUpRight(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position - (8 / 2) + 1 : position - (8 / 2)
    }

    func positionOneDiagonalDownLeft(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position + (8 / 2) : position + (8 / 2) - 1
    }

    func positionOneDiagonalDownRight(_ position: Int) -> Int {
        row(position) % 2 == 0 ? position + (8 / 2) + 1 : position + (8 / 2)
    }
    

    
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
    
    
    struct MoveFunctionSuite {
        let boardExistsInDirection: (Int) -> Bool
        let positionOneDiagonalInDirection: (Int) -> Int
        
        init(
            boardExistsInDirection: @escaping (Int) -> Bool,
            positionOneDiagonalInDirection: @escaping (Int) -> Int
        ) {
            self.boardExistsInDirection = boardExistsInDirection
            self.positionOneDiagonalInDirection = positionOneDiagonalInDirection
        }
    }
    
}
