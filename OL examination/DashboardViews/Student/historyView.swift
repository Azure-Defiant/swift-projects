import SwiftUI
import Combine

// Model for exam submission data
struct ExamSubmission: Identifiable, Codable {
    let id: Int64
    let username: String
    let questionText: String
    let examTitle: String
    let submissionDate: String?
    let score: Int?
    let status: String
    let correctAnswer: String

    enum ExamCodingKeys: String, CodingKey {
        case id
        case username
        case questionText = "question_text"
        case examTitle = "exam_title"
        case submissionDate = "submission_date"
        case score
        case status
        case correctAnswer = "correct_answer"
    }
}

struct UserIdResponse: Codable {
    let id: Int64
}


// ViewModel to manage exam history data
class HistoryViewModel: ObservableObject {
    @Published var submissionsByExam: [String: [ExamSubmission]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client

    // Load submissions for a specific user
    func loadSubmissions(userId: Int64) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await client.rpc("get_user_submissions", params: ["user_id_param": userId]).execute()
                let responseData = response.data
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let fetchedSubmissions = try decoder.decode([ExamSubmission].self, from: responseData)
                let grouped = Dictionary(grouping: fetchedSubmissions, by: { $0.examTitle })

                DispatchQueue.main.async {
                    self.submissionsByExam = grouped
                    self.submissionsByExam.forEach { examTitle, submissions in
                        let status = self.calculatePassFailStatus(submissions: submissions)
                        print("\(examTitle): \(status)")  // This prints pass/fail status for each exam
                    }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load submissions: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    
    func calculatePassFailStatus(submissions: [ExamSubmission]) -> String {
        let totalScore = submissions.reduce(0) { $0 + ($1.score ?? 0) }
        let totalPossible = submissions.count
        let passThreshold = totalPossible * 5 / 10 // Assuming pass at 50%
        return totalScore >= passThreshold ? "Pass" : "Fail"
    }
    
}



// Main History View
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedExam: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading submissions...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                } else {
                    List {
                        ForEach(viewModel.submissionsByExam.keys.sorted(), id: \.self) { examTitle in
                            NavigationLink(
                                destination: QuestionListView(
                                    examTitle: examTitle,
                                    submissions: viewModel.submissionsByExam[examTitle] ?? []
                                )
                            ) {
                                ExamRow(examTitle: examTitle, submissions: viewModel.submissionsByExam[examTitle] ?? [])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exam History")
            .onAppear {
                fetchUserIdFromUsersTable()
            }
        }
    }

    private func fetchUserIdFromUsersTable() {
        Task {
            do {
                if let email = SupabaseManager.shared.client.auth.currentUser?.email {
                    let userId = try await fetchUserIdByEmail(email: email)
                    if let userId = userId {
                        viewModel.loadSubmissions(userId: userId)
                    } else {
                        viewModel.errorMessage = "User ID not found in users table."
                    }
                } else {
                    viewModel.errorMessage = "User not logged in."
                }
            } catch {
                viewModel.errorMessage = "Error fetching user ID: \(error.localizedDescription)"
            }
        }
    }

    private func fetchUserIdByEmail(email: String) async throws -> Int64? {
        let response = try await SupabaseManager.shared.client
            .from("users")
            .select("id")
            .eq("email", value: email)
            .single()
            .execute()
        
        let userIdResponse = try JSONDecoder().decode(UserIdResponse.self, from: response.data)
        return userIdResponse.id
    }
}

// Row showing the Exam Title and Overall Status
struct ExamRow: View {
    let examTitle: String
    let submissions: [ExamSubmission]

    var body: some View {
        HStack {
            Text(examTitle).font(.headline)
            Spacer()
            Text(overallStatus())
                .foregroundColor(overallStatus() == "Pass" ? .green : .red)
        }
    }
 // OVERALL STATUS
    private func overallStatus() -> String {
        let correctCount = submissions.filter { $0.score == 1 }.count
        return correctCount == submissions.count ? "Pass" : "Fail"
    }
}

// List of Questions for Selected Exam
struct QuestionListView: View {
    let examTitle: String
    let submissions: [ExamSubmission]

    var body: some View {
        List {
            ForEach(submissions) { submission in
                QuestionRow(submission: submission)
            }
        }
        .navigationTitle(examTitle)
    }
}

struct QuestionRow: View {
    let submission: ExamSubmission

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Display the question text
            Text("Question: \(submission.questionText)")
                .font(.subheadline)
            
            // Display if the user's answer was correct or wrong
            Text("Your Answer: \(submission.status == "pass" ? "Correct" : "Wrong")")
                .foregroundColor(submission.status == "pass" ? .green : .red)
            
            // If the answer was wrong, display the correct answer
            if submission.status == "fail" {
                Text("Correct Answer: \(submission.correctAnswer)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Handle and display the submission date
            if let submissionDateString = submission.submissionDate,
               let submissionDate = parseDate(submissionDateString) {
                Text("Submitted: \(formattedDate(submissionDate))")
                    .font(.caption)
            } else {
                Text("Status: Submitted")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .shadow(radius: 2)
    }

    // Function to parse the string date to a Date
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    // Function to format the Date to a readable string
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}






struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
