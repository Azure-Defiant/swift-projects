import SwiftUI

struct HomeView: View {
    @State private var isShowingCreateExamView = false
    @EnvironmentObject var authViewModel: AuthViewModel 
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                       
                        Text("Welcome, \(authViewModel.username)")
                            .font(.title)
                            .bold()
                        
                        Text("Exam Creator")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                }
                .onAppear {
                    // Try fetching username if it is empty
                    Task {
                         if authViewModel.username.isEmpty {
                            print("Attempting to fetch username on homeView appear")
                            authViewModel.username = (try? await authViewModel.fetchUsername(email: authViewModel.currentUserEmail)) ?? "Teacher"
                            print("Fetched username on appear: \(authViewModel.username)")
                        }
                    }
                }
                .padding(.top, 40)
                .padding(.leading, 20)
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    isShowingCreateExamView.toggle()
                }) {
                    Text("Start New Form")
                        .font(.title2)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.leading, 20)
                .padding(.top, 150)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .sheet(isPresented: $isShowingCreateExamView) {
            CreateExamView()
                .transition(.move(edge: .bottom)) // Slide from the bottom
                .animation(.easeInOut, value: isShowingCreateExamView)
        }
    }
}

#Preview{
    HomeView()
        .environmentObject(AuthViewModel())
}
