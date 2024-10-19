import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme (light/dark)
    @AppStorage("isDarkMode") private var isDarkMode = false // Store user's dark mode preference
    
    var body: some View {
        NavigationView {
            VStack {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.gray)
                    .padding(.top, 150)
                
                // User Info
                Text("Josh Smith")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)

                HStack(spacing: 40) {
                    Button(action: {
                        print("Logout tapped")
                    }) {
                        VStack {
                            Image(systemName: "power")
                                .font(.title)
                                .foregroundColor(.red)
                            Text("Logout")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.top, 20)
                
                // Dark Mode Toggle
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                        .font(.headline)
                }
                .padding()
                .onChange(of: isDarkMode) { value in
                    toggleDarkMode()
                }

                // Spacer for more space before the About Us link
                Spacer().frame(height: 40) // Add space between the toggle and the About Us link
                
                // About Us Navigation Link
                NavigationLink(destination: aboutusview()) {
                    Text("About Us")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.leading, 20) // Adjusted padding to move the link to the left
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Align to the left
                
                Spacer() // Add another spacer to push content to the top
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("Profile", displayMode: .inline)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light) // Manage color scheme with SwiftUI
    }
    
    // Function to toggle dark/light mode
    private func toggleDarkMode() {
        // SwiftUI manages the dark/light mode.
    }
}

// About Us View
struct aboutusview: View {
    var body: some View {
        VStack {
            Text("About Us")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 100)
            
            Text("We Build this Proctorly app to make exam easy through online and for the best online examination")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
    
    }
}

#Preview {
    ProfileView()
}
