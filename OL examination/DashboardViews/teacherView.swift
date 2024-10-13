import SwiftUI

struct TeacherView: View {
    var body: some View {
        
        TabView {
            // Home Tab
            NavigationView {
                HomeView()
                    
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
                .navigationTitle("History")
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("History")
            }
            
            // Profile Tab
            NavigationView {
                ProfileView()
                .navigationTitle("Profile")
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


