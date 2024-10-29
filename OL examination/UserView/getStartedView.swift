import SwiftUI

struct GetStartedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

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

                    Text("Your journey to secure, seamless, and efficient online examinations starts here.")
                        .multilineTextAlignment(.center)
                        .padding(.top, -60)
                        .frame(width: 300)
                        .font(.system(size: 16, weight: .semibold))

                    Text("Already have an account? Click Sign In")
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .frame(width: 400)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()

                    // Sign In Button
                    Button("Sign In") {
                        authViewModel.isNavigatingToSignInView = true
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.top, -260)

                    Text("Choose your Role to Create an account")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, -160)

                    // Role Selection Button
                    Button("Choose Your Role") {
                        authViewModel.isNavigatingToRoleView = true
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
                // NavigationLink to RoleView
                NavigationLink(
                    destination: RoleView(),
                    isActive: $authViewModel.isNavigatingToRoleView, // Updated binding
                    label: { EmptyView() }
                )
            )
            .background(
                // NavigationLink to SignInView
                NavigationLink(
                    destination: SignInView(),
                    isActive: $authViewModel.isNavigatingToSignInView,
                    label: { EmptyView() }
                )
            )
            .onAppear {
                if authViewModel.shouldNavigateToGetStarted {
                print("Navigating to GetStartedView")
                authViewModel.shouldNavigateToGetStarted = false

                DispatchQueue.main.async {
                authViewModel.navigateToSignUp = false
                authViewModel.isNavigatingToSignInView = false
                authViewModel.isNavigatingToRoleView = false
                authViewModel.shouldNavigateToRoleSelection = false
                authViewModel.shouldNavigateToDashboard = false
                authViewModel.navigateToTeacherDashboard = false
                authViewModel.navigateToStudentDashboard = false
                 }
              }
           }
        }
    }
}

#Preview {
    let authViewModel = AuthViewModel()
    return GetStartedView()
        .environmentObject(authViewModel)
}
