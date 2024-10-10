import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var shouldHideBackButton = false

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .ignoresSafeArea()
                .scaledToFill()

            VStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .padding(.top, -300)

                Text("Sign Up")
                    .font(.custom("Poppins-Regular", size: 20))
                    .padding(.top, -130)

                // Email TextField (for sign-up)
                TextField("Email", text: $authViewModel.signUpEmail)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(Color.black)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.top, -100)

                // Username TextField (for sign-up)
                TextField("Username", text: $authViewModel.signupUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(Color.black)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.top, -50)

                // Password TextField (for sign-up)
                SecureField("Password", text: $authViewModel.signUpPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(Color.black)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.top, 1)

                // Sign Up Button
                Button(action: {
                    signUp()
                }) {
                    Text("Sign Up")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(Color.white)
                        .frame(width: 150, height: 55)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.top, 20)
                }

                // Display error message if sign-up fails
                if let errorMessage = authViewModel.error {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }

                // Navigation Link to designated dashboard based on role
                NavigationLink(
                    destination: roleBasedDashboard(selectedRole: authViewModel.selectedRole)
                      .navigationBarBackButtonHidden(shouldHideBackButton), // Hide back button based on state
                    isActive: $authViewModel.shouldNavigateToRoleSelection
                ) {
                    EmptyView() // Hidden NavigationLink
                }
            }
        }
    }

    private func signUp() {
        authViewModel.signUp(role: authViewModel.selectedRole ?? "") { success in
            if success {
                authViewModel.shouldNavigateToRoleSelection = true
                shouldHideBackButton = true // Hide back button after successful sign-up// Trigger navigation to dashboard
            }
        }
    }

    // Function to navigate users based on their role
    func roleBasedDashboard(selectedRole: String?) -> some View {
        if let role = selectedRole {
            switch role {
            case "Teacher":
                return AnyView(TeacherView()) // Replace with your actual Teacher dashboard view
            case "Student":
                return AnyView(StudentView()) // Replace with your actual Student dashboard view
            default:
                return AnyView(Text("Unknown role"))
            }
        }
        return AnyView(Text("No role selected"))
    }
}
