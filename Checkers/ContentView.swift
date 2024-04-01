import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) // Determine the size of the grid based on the smaller dimension
            BoardUI(size: size) {
                Grid(size: size) {
                    ForEach(0..<8) { y in
                        GridRow {
                            ForEach(0..<8) { x in
                                cell(i: y, j: x)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func cell(i: Int, j: Int) -> some View {
        let hasCheckerPiece = (i + j) % 2 == 0 // Determine if the cell should have a checker piece
        let isWhitePiece = (i + j) % 2 == 0 && i < 3 // Determine if the checker piece is white
        let isBlackPiece = (i + j) % 2 == 0 && i > 4 // Determine if the checker piece is black
        
        return ZStack {
            Rectangle()
                .fill((i + j) % 2 == 0 ? Color.red : Color.black) // Alternating red and black colors for the checkerBoardUI pattern
            
            if hasCheckerPiece {
                Circle()
                    .fill(isWhitePiece ? Color.white : Color.black) // Conditionally render white or black checker piece
                    .frame(width: 30, height: 30) // Adjust the size of the checker piece
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct BoardUI<Content>: View where Content: View {
    let size: CGFloat
    let content: () -> Content
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray) // BoardUI background color
                .frame(width: size, height: size)
            content()
        }
    }
}

struct Grid<Content>: View where Content: View {
    let size: CGFloat
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(width: size, height: size)
    }
}

struct GridRow<Content>: View where Content: View {
    let content: () -> Content
    
    var body: some View {
        HStack(spacing: 0) {
            content()
        }
    }
}
