import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Image("background") // Corrected the image name (removed parentheses)
                .resizable()
                .ignoresSafeArea()
                .scaledToFill()
            
            VStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .padding(.top, -300)
                
                Text("Sign In")
                    .font(.custom("Poppins-Regular", size: 20))
                    .padding(.top, -130)
                
                TextField("Email", text: $viewModel.signInEmail)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(Color.black)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.top, -100)
                
                SecureField("Password", text: $viewModel.signInPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(Color.black)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.top, -50)
                
                Button(action: {
                   
                    viewModel.signIn()
                
                }) {
                    Text("Sign In")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(Color.white)
                        .frame(width: 150, height: 55)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.top, 20)
                }
                
                // Show error message if sign in fails
                if let errorMessage = viewModel.error {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                
                NavigationLink(destination: RoleView(), isActive: $viewModel.shouldNavigateToRoleSelection) {
                    EmptyView() // Navigation link to role view
                }
            }
        }
    }
}

#Preview {
    SignInView()
}
