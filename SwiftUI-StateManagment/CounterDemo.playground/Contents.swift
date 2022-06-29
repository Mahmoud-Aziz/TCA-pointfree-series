//: Use @State for non persistent biding
// Use @ObservedObject for persistent binding
// permitive types doesn't conform to ObservableObject so we wrap it in a new type

import SwiftUI
import PlaygroundSupport
import Combine

struct ContentView: View {
     var state: AppState
    @State var presentSheet: Bool = false

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: CounterView(state: self.state)) {
                    Text("Counter Demo")
                }
                NavigationLink(destination: EmptyView()) {
                    Text("Favorite primes")
                }
            }.navigationTitle("State Management")
        }
    }
}

class AppState: ObservableObject {
    let objectWillChange: some Publisher = ObservableObjectPublisher()
    
    @Published var count = 0
    @Published var favoritePrime: [Int] = []
}

struct CounterView: View {
    
    @ObservedObject var state: AppState
    @State var updatedText: String?
    @State var textColor: Color?
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    self.state.count -= 1
                } label: {
                    Text("-")
                }
                
                Text("\(self.state.count)")
                Button {
                    self.state.count += 1
                } label: {
                    Text("+")
                    
                }
            }
            Button {
                if isPrime(self.state.count) {
                    updatedText = "yes"
                    textColor = .green
                } else {
                    updatedText = "no "
                    textColor = .red
                }
            } label: {
                Text("is this prime?")
            }
            Text(updatedText ?? "").foregroundColor(textColor)
            Button {
                print("")
            } label: {
                Text("what's the \(ordinal(self.state.count)) prime?")
                
            }
        }.font(.title)
            .navigationTitle("Counter Demo")
    }
}

private func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(from: n as NSNumber) ?? ""
}

private func isPrime(_ number: Int) -> Bool {
    return number > 1 && !(2..<number).contains { number % $0 == 0 }
}

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView(state: AppState()))
