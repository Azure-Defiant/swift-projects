import SwiftUI
import Supabase

struct homeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var exams: [Exam] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground) // This will automatically adapt to light or dark mode
                    .ignoresSafeArea()
                
                VStack {
                    // Profile Section
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray) // Consider changing if needed in dark mode
                        
                        VStack(alignment: .leading) {
                            Text("Welcome,Josh!")
                                .font(.title)
                                .bold()
                            
                            Text("Student Exam Portal")
                                .font(.subheadline)
                                .foregroundColor(.secondary) // Adjusts for light and dark mode
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            ForEach(exams) { exam in
                                NavigationLink(destination: ExamTakingView(examId: exam.id, userId: Int64(authViewModel.userRoleId ?? 0))) {
                                    DashboardButtonView(label: exam.title)
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
                fetchExams()
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

    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundColor(.primary) // Use primary to automatically adjust text color based on the theme
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground)) // A lighter background for both modes
            .cornerRadius(10)
            .shadow(color: .gray, radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}


struct Home_Previews: PreviewProvider {
    static var previews: some View {
        homeView()
            .environmentObject(AuthViewModel()) // Inject the view model here
    }
}
