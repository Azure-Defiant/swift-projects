import SwiftUI
import Combine

// Model for exam submission data
struct ExamSubmission: Identifiable, Codable {
    let id: Int64
    let username: String
    let questionText: String
    let examTitle: String
    let submissionDate: String? // Treating this as a string since it's returned as a string from the database
    let score: Int?
    let status: String
    
    // Coding keys to map JSON fields to Swift property names
    enum ExamCodingKeys: String, CodingKey {
        case id
        case username
        case questionText = "question_text"
        case examTitle = "exam_title"
        case submissionDate = "submission_date"
        case score
        case status
    }
}

class HistoryViewModel: ObservableObject {
    @Published var submissions: [ExamSubmission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    // Load submissions dynamically from Supabase
    func loadSubmissions(userId: Int64) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Construct the raw SQL query
                let sqlQuery = """
                SELECT 
                    submissions.id,
                    users.username,
                    exam_questions.question_text,
                    exams.title AS exam_title,
                    submissions.submission_date,
                    submissions.score,
                    submissions.status
                FROM 
                    submissions
                INNER JOIN users ON submissions.user_id = users.id
                INNER JOIN exam_questions ON submissions.exam_question_id = exam_questions.id
                INNER JOIN exams ON exam_questions.exam_id = exams.id
                WHERE 
                    submissions.user_id = \(userId)
                ORDER BY 
                    submissions.submission_date DESC;
                """

                // Call the actual data fetching method using 'rpc' to execute raw SQL
                let fetchedSubmissions = try await fetchSubmissions(sqlQuery: sqlQuery)
                DispatchQueue.main.async {
                    self.submissions = fetchedSubmissions
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
    private func fetchSubmissions(sqlQuery: String) async throws -> [ExamSubmission] {
        let response = try await client
            .rpc("execute_sql", params: ["query": sqlQuery])
            .execute()

        // Directly access response.data since it's not optional in your Supabase client version
        let responseData = response.data

        print("Raw response data (JSON): \(String(data: responseData, encoding: .utf8) ?? "No data")")

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Since submissionDate is treated as a string in the model, no need for custom date decoding
        do {
            let submissions = try decoder.decode([ExamSubmission].self, from: responseData)
            return submissions
        } catch let decodingError as DecodingError {
            print("Decoding Error: \(decodingError.localizedDescription)")
            throw decodingError
        } catch {
            print("General Error: \(error.localizedDescription)")
            throw error
        }
    }
}

// HistoryView struct should be outside the ViewModel
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading submissions...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if !viewModel.submissions.isEmpty {
                List(viewModel.submissions) { submission in
                    SubmissionRow(submission: submission) // Using a separate row component for cleanliness
                }
            } else {
                Text("No submissions found.")
            }
        }
        .onAppear {
            // Fetch the userId from the 'users' table
            fetchUserIdFromUsersTable()
        }
    }
    
    private func fetchUserIdFromUsersTable() {
        Task {
            do {
                if let email = SupabaseManager.shared.client.auth.currentUser?.email {
                    // Query the 'users' table using email to get the userId
                    let userId = try await fetchUserIdByEmail(email: email)
                    if let userId = userId {
                        // Once you have the userId, load the submissions
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
    
    struct UserIdResponse: Codable {
        let id: Int64
    }
    
    private func fetchUserIdByEmail(email: String) async throws -> Int64? {
        let response = try await SupabaseManager.shared.client
            .from("users")
            .select("id")
            .eq("email", value: email)
            .single()
            .execute()
        
        print("Response data: \(String(data: response.data, encoding: .utf8) ?? "No data")")
        
        let userIdResponse = try JSONDecoder().decode(UserIdResponse.self, from: response.data)
        return userIdResponse.id
    }
}


// Row to display individual submission details
struct SubmissionRow: View {
    let submission: ExamSubmission

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(submission.username)
                .font(.headline)
            Text("Exam Title: \(submission.examTitle)")
                .font(.subheadline)
            Text("Question: \(submission.questionText)")
                .font(.subheadline)

            // Handle optional score
            if let score = submission.score {
                Text("Score: \(score)")
            } else {
                Text("Score: N/A")
            }

            Text("Status: \(submission.status.capitalized)")
                .foregroundColor(submission.status == "pass" ? .green : .red)

            // Safely parse the submissionDate string to Date
            if let submissionDateString = submission.submissionDate,
               let submissionDate = parseDate(submissionDateString) {
                Text("Submitted: \(formattedDate(submissionDate))")
                    .font(.caption)
            } else {
                Text("Submitted: N/A")
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
