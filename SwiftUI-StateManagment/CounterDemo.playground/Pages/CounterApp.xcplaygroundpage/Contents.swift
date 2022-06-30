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
                NavigationLink(destination: CounterView(state: state)) {
                    Text("Counter Demo")
                }
                NavigationLink(destination: FavoritePrimesView(state: state)) {
                    Text("Favorite primes")
                }
            }.navigationTitle("State Management")
        }
    }
}

class AppState: ObservableObject, Identifiable {
    let objectWillChange: some Publisher = ObservableObjectPublisher()
    
    @Published var count = 0
    @Published var favoritePrime: [Int] = []
    @Published var alertNthPrime: Int?
    @Published var isPrimeSheetShown: Bool = false

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
                    print(state.count)
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
                nthPrime(state.count) { prime in
                    state.alertNthPrime = prime
                }
            }
        label: {
            Text("what's the \(ordinal(self.state.count)) prime?")
        }
        }.font(.title)
            .navigationTitle("Counter Demo")
            .sheet(isPresented: $state.isPrimeSheetShown) {
                isPrimeSheetView(state: state)
            }.alert(item: $state.alertNthPrime) { prime in
                Alert(
                    title: Text("The prime is"),message: Text("\(prime)"),
                    dismissButton: .cancel()
                )
            }
    }
}

public protocol IdentifiableByHashable: Identifiable {}

extension IdentifiableByHashable where Self: Hashable {
    public var id: Int { hashValue }
}

extension Int : IdentifiableByHashable {
    
}
  

struct isPrimeSheetView: View {
    @ObservedObject var state: AppState
    
    var body: some View {
        
        if isPrime(state.count) {
            Text("\(state.count) is prime")
            if state.favoritePrime.contains(state.count) {
                Button {
                    state.favoritePrime.removeAll(where: { $0 == state.count })
                } label: {
                    Text("Remove from favorite primes")
                }
            } else {
                Button {
                    state.favoritePrime.append(state.count)
                } label: {
                    Text("Save to favorite primes")
                }
            }
            
        } else {
            Text("\(self.state.count) is not prime")
        }
    }
}

struct FavoritePrimesView: View {
    @ObservedObject var state: AppState
    
    var body: some View {
        EmptyView()
            .navigationTitle(Text("Favorite Primes"))
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

struct WolframAlphaResult: Decodable {
    let queryresult: QueryResult
    
    struct QueryResult: Decodable {
        let pods: [Pod]
        
        struct Pod: Decodable {
            let primary: Bool?
            let subpods: [SubPod]
            
            struct SubPod: Decodable {
                let plaintext: String
            }
        }
    }
}

func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) {
    
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: "RKR7JK-JTL9J8QJ33")
    ]
    
    URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, response, error in
        callback(
            data.flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
        )
    }.resume()
}

func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) {
    wolframAlpha(query: "prime \(n)") { result in
        callback(
            result
                .flatMap {
                    $0.queryresult
                        .pods
                        .first(where: { $0.primary == .some(true) })?
                        .subpods
                        .first?
                        .plaintext
                }
                .flatMap(Int.init)
        )
    }
}



PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView(state: AppState()))
