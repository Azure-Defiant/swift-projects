import SwiftUI

struct profileView: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme (light/dark)
    @AppStorage("isDarkMode") private var isDarkMode = false // Store user's dark mode preference
    
    // Inject AuthViewModel into the view
    @StateObject private var authViewModel = AuthViewModel()
    
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
                Text("Josh Smith") // Replace with dynamic user data if available
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                
                Text("josh.smith@example.com") // Replace with dynamic user email
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
                
                HStack(spacing: 40) {
                    Button(action: {
                        print("Edit Profile tapped")
                    }) {
                        VStack {
                            Image(systemName: "pencil")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text("Edit")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        authViewModel.signOut() // Call the sign-out function from AuthViewModel
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
                
                NavigationLink(destination: AboutUsView()) {
                    Text("About Us")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                }
                
                // Dark Mode Toggle
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                        .font(.headline)
                }
                .padding()
                .onChange(of: isDarkMode) { value in
                    toggleDarkMode()
                }
                
                Spacer()
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
        // SwiftUI handles this with the .preferredColorScheme() modifier
    }
}

// About Us View
struct AboutUsView: View {
    var body: some View {
        VStack {
            Text("About Us")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 100)
            
            Text("This is the About Us page. Here you can add information about your app or company.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("About Us")
    }
}

// Preview
#Preview {
    ProfileView()
}
