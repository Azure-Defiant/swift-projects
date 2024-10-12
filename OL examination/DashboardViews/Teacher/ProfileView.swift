//
//  profileView.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/2/24.
//
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
                
                Text("josh.smith@example.com")
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
                
                
                NavigationLink(destination: aboutusview()) {
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
        // No need to override the interface style manually in iOS 15; SwiftUI manages it.
        // We just use the .preferredColorScheme() modifier in the view.
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
            
            Text("This is the About Us page. Here you can add information about your app or company.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("About Us")
    }
}

#Preview {
    ProfileView()
}
