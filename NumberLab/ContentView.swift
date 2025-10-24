import SwiftUI

struct ContentView: View {
    let sidebarItems: [SidebarItem] = [
//        SidebarItem(title: "Collatz Chains"),
        SidebarItem(title: "Collatz 30 bit", nbit: 30),
        SidebarItem(title: "Collatz 100 bit", nbit: 100),
        SidebarItem(title: "Collatz 200 bit", nbit: 200),
    ]

    var body: some View {
        NavigationView {
            List(sidebarItems) { item in
                if item.title.starts(with: "Collatz") {
                    let nbit = item.nbit
                    NavigationLink(destination: HistogramView(nbit: nbit)) {
                        Text(item.title)
                    }
                } else {
                    NavigationLink(destination: Text("Content for \(item.title)")) {
                        Text(item.title)
                    }
                }
            }
            
            Text("Select an item from the sidebar")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
    
struct SidebarItem: Identifiable {
    let id = UUID()
    let title: String
    let nbit: Int
}
