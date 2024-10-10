import SwiftUI

struct TeacherView: View {
    var body: some View {
        // Main TabView for bottom navigation
        TabView {
            // Home Tab
            NavigationView {
                HomeView() // Ensure HomeView is defined and returns a valid View
                    .navigationTitle("Home") // Optional: Set a title for the Home view
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            // Records Tab
            NavigationView {
                RecordsView() // Ensure RecordsView is defined and returns a valid View
                    .navigationTitle("Records") // Optional: Set a title for the Records view
            }
            .tabItem {
                Image(systemName: "doc.plaintext")
                Text("Records")
            }
            
            // History Tab
            NavigationView {
                VStack {
                    Text("History")
                        .font(.largeTitle)
                        .padding()
                    // Add your history content here
                }
                .navigationTitle("History") // Title in the navigation bar
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("History")
            }
            
            // Profile Tab
            NavigationView {
                VStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .padding()
                    // Add your profile content here
                }
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


