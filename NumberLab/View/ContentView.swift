import SwiftUI

struct ContentView: View {
    let sidebarItems: [SidebarItem] = [
        SidebarItem(title: "Bit Strings"),
        SidebarItem(title: "Syracuse Chains", nchain: 32),
        SidebarItem(title: "Syracuse Chain Stats", nchain: 1024*1024),
        SidebarItem(title: "Syracuse Halo", nmax: 1024),
        SidebarItem(title: "Syracuse Graph 16 bit", nbit: 16),
        SidebarItem(title: "Syracuse Graph 20 bit", nbit: 20),
        SidebarItem(title: "Syracuse Histogram 30 bit", nbit: 30),
        SidebarItem(title: "Syracuse Histogram 100 bit", nbit: 100),
        SidebarItem(title: "Syracuse Histogram 200 bit", nbit: 200),
    ]

    var body: some View {
        NavigationView {
            List(sidebarItems) { item in
                if item.title.starts(with: "Bit Strings") {
                    NavigationLink(destination: BitStringView()) {
                        Text(item.title)
                    }
                } else if item.title.starts(with: "Syracuse Chains") {
                    let nchain = item.nchain!
                    NavigationLink(destination: ChainView(nchain: nchain)) {
                        Text(item.title)
                    }
                } else if item.title.starts(with: "Syracuse Chain Stats") {
                    let nchain = item.nchain!
                    NavigationLink(destination: ChainStatsView(nchain: nchain)) {
                        Text(item.title)
                    }
                } else if item.title.starts(with: "Syracuse Graph") {
                    let nchain = 1 << item.nbit!
                    NavigationLink(destination: SyracuseGraphView(nchain: nchain)) {
                        Text(item.title)
                    }
                } else if item.title.starts(with: "Syracuse Histogram") {
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
    let index: Int?
    let nmax: Int?

    init(title: String, nbit: Int? = nil, nchain: Int? = nil, index: Int? = nil, nmax: Int? = nil) {
        self.title = title
        self.nbit = nbit
        self.nchain = nchain
        self.index = index
        self.nmax = nmax
    }
}
