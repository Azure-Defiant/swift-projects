
import SwiftUI

struct StudentView: View {
    var body: some View {
        TabView {
            homeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
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
