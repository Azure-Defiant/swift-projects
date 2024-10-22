import SwiftUI
import Supabase

struct homeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel // Use @EnvironmentObject
    @State private var exams: [Exam] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.Uicolor
                    .ignoresSafeArea()
                
                VStack {
                    // Profile Section
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            // Access currentUserEmail from the AuthViewModel
                            Text("Welcome, \(authViewModel.signupUsername)!")
                                .font(.title)
                                .bold()
                            
                            Text("Student Exam Portal")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding()
                    
                    // ScrollView with Exams
                    ScrollView {
                        VStack(spacing: 25) {
                            ForEach(exams) { exam in
                                NavigationLink(destination: ExamTakingView(examId: exam.id, userId: Int64(authViewModel.userRoleId ?? 0))) { // Provide default userId
                                    DashboardButtonView(label: exam.title, color: .blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                }
                .navigationBarTitle("Dashboard", displayMode: .inline)
            }
            .onAppear {
                fetchExams() // Corrected function call
            }
        }
    }
    
    private func fetchExams() {
        let supabaseClient = SupabaseManager.shared.client

        Task {
            do {
                // Execute the query using async/await
                let response = try await supabaseClient
                    .from("exams")
                    .select("*")
                    .execute()

            
                let data = response.data

                
                if let jsonData = String(data: data, encoding: .utf8) {
                    print("Raw JSON data: \(jsonData)")
                }

                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let decodedExams = try decoder.decode([Exam].self, from: data)

                
                self.exams = decodedExams
                
            } catch {
                // Handle any errors during the async operation
                print("Error fetching exams: \(error.localizedDescription)")
            }
        }
    }
}

struct DashboardButtonView: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(10)
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        homeView()
            .environmentObject(AuthViewModel()) // Inject the view model here
    }
}
