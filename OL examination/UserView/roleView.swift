import SwiftUI


struct RoleButton: View {
    let role: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action() // Trigger the action closure
        }) {
            Text(role)
                .font(.custom("Poppins-Bold", size: 16))
                .frame(width: 120, height: 50)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(10)
        }
    }
}

// RoleView Struct
struct RoleView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .padding(.top, -300)

                Text("Choose Your Role")
                    .font(.custom("Poppins-Bold", size: 20))
                    .frame(width: 200, height: 40)
                    .padding(.top, -150)

                HStack(spacing: 20) {
                    RoleButton(role: "Teacher") {
                        selectRole(role: "Teacher")
                    }

                    Text("OR")
                        .font(.custom("Poppins-Regular", size: 20))

                    RoleButton(role: "Student") {
                        selectRole(role: "Student")
                    }
                }
            }

            // Navigate to SignUpView after role selection
            NavigationLink(
                destination: SignUpView(),
                isActive: $authViewModel.navigateToSignUp
            ) {
                EmptyView()
            }
        }
    }

    private func selectRole(role: String) {
        print("Role selected: \(role)")
        authViewModel.selectedRole = role // Set the selected role
        authViewModel.navigateToSignUp = true // Trigger navigation
    }
}


#Preview{
    RoleView()
}
