import SwiftUI

struct TeacherView: View {
    var body: some View {
        // Main TabView for bottom navigation
        TabView {
            // Home Tab
            NavigationView {
                HomeView() // Ensure HomeView is defined and returns a valid View
                    
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            // Records Tab
            NavigationView {
                RecordsView()

            }
            .tabItem {
                Image(systemName: "doc.plaintext")
                Text("Records")
            }
            
            // History Tab
            NavigationView {
                HistoryView()
                .navigationTitle("History") // Title in the navigation bar
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("History")
            }
            
            // Profile Tab
            NavigationView {
                ProfileView()
                .navigationTitle("Profile") // Title in the navigation bar
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
        }
    }
}

#Preview {
    TeacherView()
}


