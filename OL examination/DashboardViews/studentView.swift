
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
                VStack {
                    Text("History")
                        .font(.largeTitle)
                        .padding()
                    // Add your history content here
                }
                .navigationTitle("History")
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
                .navigationTitle("Profile")
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
        }
    }
}

#Preview{
    StudentView()
}
