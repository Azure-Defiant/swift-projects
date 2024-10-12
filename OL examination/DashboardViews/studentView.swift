
import SwiftUI

struct StudentView: View {
    var body: some View {
        TabView {
            // Home Tab
            homeView() // Assuming HomeView is defined elsewhere
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Records Tab
            recordView() // Assuming RecordView is defined elsewhere
                .tabItem {
                    Image(systemName: "doc.plaintext")
                    Text("Records")
                }
            
            // History Tab
            NavigationView {
                historyView()
                .navigationTitle("History")
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("History")
            }
            
            // Profile Tab
            NavigationView {
                profileView()
                 .navigationTitle("Profile")
                
            }
            
            
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("Profile")
            }
        }
    }
}

#Preview{
    StudentView()
}
