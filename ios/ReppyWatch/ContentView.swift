import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodaySummaryView()
                .tag(0)

            WaterLogView()
                .tag(1)

            FastingStatusView()
                .tag(2)

            StreakView()
                .tag(3)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
}
