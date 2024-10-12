import SwiftUI
import Supabase

struct ExamSubmission: Identifiable, Codable {
    let id: Int64
    let username: String
    let examQuestionId: Int64
    let submissionDate: Date
    let score: Int
    let status: String
}

class RecordsViewModel: ObservableObject {
    @Published var submissions: [ExamSubmission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    func fetchSubmissions() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await client
                    .from("submissions")
                    .select("""
                    id,
                    users!inner(username),
                    exam_question_id,
                    submission_date,
                    score,
                    status
                    """)
                    .order("submission_date", ascending: false)
                    .execute()
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                
                let decodedSubmissions = try decoder.decode([ExamSubmission].self, from: response.data)
                
                DispatchQueue.main.async {
                    self.submissions = decodedSubmissions
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
}

struct RecordsView: View {
    @StateObject private var viewModel = RecordsViewModel()
    @State private var searchText = ""
    @State private var statusFilter: String?
    @State private var sortOrder: SortOrder = .descending
    
    var filteredSubmissions: [ExamSubmission] {
        viewModel.submissions.filter { submission in
            (searchText.isEmpty || submission.username.localizedCaseInsensitiveContains(searchText)) &&
            (statusFilter == nil || submission.status == statusFilter)
        }.sorted {
            sortOrder == .ascending ? $0.submissionDate < $1.submissionDate : $0.submissionDate > $1.submissionDate
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading submissions...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    List(filteredSubmissions) { submission in
                        SubmissionRow(submission: submission)
                    }
                    .searchable(text: $searchText, prompt: "Search by username")
                }
            }
            .navigationTitle("Exam Submissions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $statusFilter) {
                            Text("All").tag(nil as String?)
                            Text("Pass").tag("pass" as String?)
                            Text("Fail").tag("fail" as String?)
                        }
                        Picker("Sort", selection: $sortOrder) {
                            Text("Newest First").tag(SortOrder.descending)
                            Text("Oldest First").tag(SortOrder.ascending)
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchSubmissions()
        }
    }
}

struct SubmissionRow: View {
    let submission: ExamSubmission
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(submission.username)
                .font(.headline)
            Text("Exam ID: \(submission.examQuestionId)")
                .font(.subheadline)
            Text("Score: \(submission.score)")
            Text("Status: \(submission.status.capitalized)")
                .foregroundColor(submission.status == "pass" ? .green : .red)
            Text("Submitted: \(formattedDate(submission.submissionDate))")
                .font(.caption)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

enum SortOrder {
    case ascending, descending
}

#Preview {
    RecordsView()
}
