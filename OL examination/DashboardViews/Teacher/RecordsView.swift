import SwiftUI
import Supabase



// ViewModel to fetch and manage submissions for the teacher's view
class RecordsViewModel: ObservableObject {
    @Published var submissions: [ExamSubmission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client

    // Fetch all student submissions for the teacher
    func fetchSubmissions() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
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
                ORDER BY 
                    submissions.submission_date DESC;
                """

                // Fetch the submissions using the same query method
                let fetchedSubmissions = try await fetchSubmissions(sqlQuery: sqlQuery)
                DispatchQueue.main.async {
                    self.submissions = fetchedSubmissions
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch submissions: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    // Fetch submissions using the raw SQL query via the RPC function
    private func fetchSubmissions(sqlQuery: String) async throws -> [ExamSubmission] {
        let response = try await client
            .rpc("execute_sql", params: ["query": sqlQuery])
            .execute()

        // Directly access response.data (no need for optional binding)
        let responseData = response.data

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // Decode the responseData into an array of ExamSubmission
        let submissions = try decoder.decode([ExamSubmission].self, from: responseData)
        return submissions
    }
}

// Main View for displaying all student exam records for the teacher
struct RecordsView: View {
    @StateObject private var viewModel = RecordsViewModel()
    @State private var searchText = ""
    @State private var statusFilter: String?
    @State private var sortOrder: SortOrder = .descending

    // Filter and sort submissions based on search text and status
    var filteredSubmissions: [ExamSubmission] {
        viewModel.submissions.filter { submission in
            // Search based on username
            (searchText.isEmpty || submission.username.localizedCaseInsensitiveContains(searchText)) &&
            // Filter based on status (if selected)
            (statusFilter == nil || submission.status == statusFilter)
        }
        .sorted {
            // Sort based on the sort order (date ascending/descending)
            guard let date1 = $0.submissionDate, let date2 = $1.submissionDate else { return false }
            return sortOrder == .ascending ? date1 < date2 : date1 > date2
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    // Search Bar for username
                    SearchBar(text: $searchText)
                        .padding([.horizontal, .top], 16)

                    // Filter and Sort options
                    HStack {
                        FilterPicker(statusFilter: $statusFilter)
                        SortPicker(sortOrder: $sortOrder)
                    }
                    .padding(.horizontal)

                    // Display the content in a ScrollView
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView("Loading submissions...")
                                .padding(.top, 50)
                        } else if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.top, 50)
                        } else if filteredSubmissions.isEmpty {
                            Text("No submissions found.")
                                .foregroundColor(.gray)
                                .padding(.top, 50)
                        } else {
                            // Show filtered submissions
                            VStack(spacing: 16) {
                                ForEach(filteredSubmissions) { submission in
                                    SubmissionRow(submission: submission)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                    .onAppear {
                        viewModel.fetchSubmissions()
                    }
                }
            }
            .navigationBarTitle("Student Records", displayMode: .inline)
        }
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

            Text("Score: \(submission.score != nil ? "\(submission.score!)" : "N/A")")
            Text("Status: \(submission.status.capitalized)")
                .foregroundColor(submission.status == "pass" ? .green : .red)

            if let submissionDate = submission.submissionDate, let parsedDate = parseDate(submissionDate) {
                Text("Submitted: \(formattedDate(parsedDate))")
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

// Search Bar
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search by username", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .shadow(radius: 2)
        }
    }
}

// Filter Picker
struct FilterPicker: View {
    @Binding var statusFilter: String?

    var body: some View {
        Picker("Filter", selection: $statusFilter) {
            Text("All").tag(String?.none)
            Text("Pass").tag(String?.some("pass"))
            Text("Fail").tag(String?.some("fail"))
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(maxWidth: .infinity)
    }
}

// Sort Picker
struct SortPicker: View {
    @Binding var sortOrder: SortOrder

    var body: some View {
        Picker("Sort by Date", selection: $sortOrder) {
            Text("Newest").tag(SortOrder.descending)
            Text("Oldest").tag(SortOrder.ascending)
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(maxWidth: .infinity)
    }
}

// Enum for Sort Order
enum SortOrder {
    case ascending, descending
}

// Preview
struct RecordsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordsView()
    }
}
