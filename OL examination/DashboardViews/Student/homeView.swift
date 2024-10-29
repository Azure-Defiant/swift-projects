import SwiftUI
import Supabase

struct homeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var exams: [Exam] = []
    @StateObject private var examHide = ExamHide()  // Initialize ExamHide here
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground) // Adapts to light or dark mode
                    .ignoresSafeArea()
                
                VStack {
                    // Profile Section
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                           
                            Text("Welcome, \(authViewModel.username)")
                                .font(.title)
                                .bold()
                            
                            Text("Student Exam Portal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .onAppear {
                        // Try fetching username if it is empty
                        Task {
                             if authViewModel.username.isEmpty {
                                print("Attempting to fetch username on homeView appear")
                                authViewModel.username = (try? await authViewModel.fetchUsername(email: authViewModel.currentUserEmail)) ?? "Student"
                                print("Fetched username on appear: \(authViewModel.username)")
                            }
                        }
                    }
                    .padding()
                    
                    // Display filtered exams
                    ScrollView {
                        VStack(spacing: 25) {
                            ForEach(filteredExams) { exam in  // Use filteredExams here
                                NavigationLink(destination: ExamTakingView(
                                    examId: exam.id,
                                    userId: Int64(authViewModel.userRoleId ?? 0),
                                    examHide: examHide
                                )) {
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
    
    // Computed property to filter out submitted exams
    private var filteredExams: [Exam] {
        exams.filter { !examHide.submittedExamIds.contains($0.id) }
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
                print("Error fetching exams: \(error.localizedDescription)")
            }
        }
    }
}

// Button view for each exam
struct DashboardButtonView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
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
