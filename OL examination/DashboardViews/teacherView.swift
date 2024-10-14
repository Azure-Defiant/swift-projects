import SwiftUI

struct TeacherView: View {
    var body: some View {
        NavigationView { // Wrap the entire TabView in one NavigationView
            TabView {
                // Home Tab
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                
                // Records Tab
                RecordsView()
                    .tabItem {
                        Image(systemName: "doc.plaintext")
                        Text("Records")
                    }
                
                // History Tab
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
                
                // Profile Tab
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
            }
        }
    }
}

#Preview {
    TeacherView()
}
