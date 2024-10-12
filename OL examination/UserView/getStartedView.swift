import SwiftUI

struct GetStartedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isNavigatingToRoleView: Bool = false // State variable for Role navigation
    @State private var isNavigatingToSignInView: Bool = false // State variable for Sign In navigation

    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.Uicolor
                    .ignoresSafeArea()

                VStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 400)
                        .padding(.top, 20)

                    Text("Your journey to secure, seamless, and efficient online examinations starts here. Get ready to experience a new standard in testing, where integrity meets innovation.")
                        .multilineTextAlignment(.center)
                        .padding(.top, -60)
                        .frame(width: 300)
                        .font(.system(size: 16, weight: .semibold))

                    Text("Do you already have an account? Click Sign In")
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .frame(width: 400)
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    // Button to navigate to SignInView
                    Button("Sign In") {
                        isNavigatingToSignInView = true
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.top, -240)

                    Text("Choose your Role to Create an account")
                        .multilineTextAlignment(.center)
                        .padding(.top, -160)
              
                        
                        
                        
                    .frame(width: 300)
                        .font(.system(size: 14, weight: .semibold))

                    // Button to navigate to RoleView
                    Button("Choose Your Role") {
                        isNavigatingToRoleView = true
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.top, -140)
                }
            }
            .navigationBarHidden(true)
            .background(
                // NavigationLink to RoleView based on the state
                NavigationLink(
                    destination: RoleView(),
                    isActive: $isNavigatingToRoleView,
                    label: {
                        EmptyView() // Hidden NavigationLink for RoleView
                    }
                )
            )
            .background(
                // NavigationLink to SignInView based on the state
                NavigationLink(
                    destination: SignInView(), // Change this to your actual SignInView
                    isActive: $isNavigatingToSignInView,
                    label: {
                        EmptyView() // Hidden NavigationLink for SignInView
                    }
                )
            )
        }
    }
}

#Preview {
    let authViewModel = AuthViewModel()
    return GetStartedView()
        .environmentObject(authViewModel)
}
