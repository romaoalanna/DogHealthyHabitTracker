import SwiftUI

struct ContentView: View {
    var body: some View {
        DogListView()
            .tint(DogTheme.accentOrange)
    }
}

#Preview {
    ContentView()
}
