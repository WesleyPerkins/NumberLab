import SwiftUI

struct ContentView: View {
    let sidebarItems: [SidebarItem] = [
        SidebarItem(title: "Bit Strings"),
        SidebarItem(title: "Collatz Chains", nchain: 32),
        SidebarItem(title: "Collatz Histogram 30 bit", nbit: 30),
        SidebarItem(title: "Collatz Histogram 100 bit", nbit: 100),
        SidebarItem(title: "Collatz Histogram 200 bit", nbit: 200),
    ]

    var body: some View {
        NavigationView {
            List(sidebarItems) { item in
                if item.title.starts(with: "Bit Strings") {
                    NavigationLink(destination: BitStringView()) {
                        Text(item.title)
                    }
                } else if item.title.starts(with: "Collatz Chains") {
                    let nchain = item.nchain!
                    NavigationLink(destination: ChainView(nchain: nchain)) {
                        Text(item.title)
                    }
                } else if item.title.starts(with: "Collatz Histogram") {
                    let nbit = item.nbit!
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
    let nbit: Int?
    let nchain: Int?
    
    init(title: String, nbit: Int? = nil, nchain: Int? = nil) {
        self.title = title
        self.nbit = nbit
        self.nchain = nchain
    }
}
