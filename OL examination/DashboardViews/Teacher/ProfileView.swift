import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme (light/dark)
    @AppStorage("isDarkMode") private var isDarkMode = false // Store user's dark mode preference
    
    @EnvironmentObject var authViewModel: AuthViewModel // Use EnvironmentObject

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
                Text(authViewModel.username.isEmpty ? "Teacher" : authViewModel.username)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                
                HStack(spacing: 40) {
                    Button(action: {
                        Task {
                            await authViewModel.signOut() // Run the async function inside Task
                        }
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

                // NavigationLink to trigger navigation to GetStartedView upon sign out
                NavigationLink(
                    destination: GetStartedView(),
                    isActive: $authViewModel.shouldNavigateToGetStarted
                ) {
                    EmptyView()
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

                Spacer().frame(height: 40)
                
                // About Us Navigation Link
                NavigationLink(destination: AboutUsViews()) {
                    Text("About Us")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.leading, 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("Profile", displayMode: .inline)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    // Function to toggle dark/light mode
    private func toggleDarkMode() {
        // SwiftUI manages the dark/light mode.
    }
}

// About Us View
struct AboutUsViews: View {
    var body: some View {
        VStack {
            Text("About Us")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 100)
            
            Text("Welcome to Proctorly, your trusted partner in revolutionizing the educational experience. Our app is designed to facilitate seamless online examinations, bridging the gap between teachers and students by providing a robust platform for creating, managing, and taking exams. At Proctorly, we are committed to enhancing academic integrity and making the testing process more accessible, efficient, and secure for educational institutions around the world. Join us in embracing the future of education, where technology meets learning.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("About Us")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
