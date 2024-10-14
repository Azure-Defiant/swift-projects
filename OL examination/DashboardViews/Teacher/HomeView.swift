import SwiftUI

struct HomeView: View {
    @State private var isShowingCreateExamView = false
    var userName: String = "User"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text("Welcome, \(userName)!")
                            .font(.title)
                            .bold()
                        
                        Text("Exam Creator")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
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
}
