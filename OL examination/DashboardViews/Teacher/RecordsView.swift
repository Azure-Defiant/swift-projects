import SwiftUI
import Supabase

// Model for Exam Submission Data
struct ExamSubmission: Identifiable, Codable {
    let id: Int64
    let username: String
    let examQuestionId: Int64
    let submissionDate: Date
    let score: Int
    let status: String
}

// View Model to fetch and manage submissions
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

// Main View for Displaying Records
struct RecordsView: View {
    @StateObject private var viewModel = RecordsViewModel()
    @State private var searchText = ""
    @State private var statusFilter: String?
    @State private var sortOrder: SortOrder = .descending

    var filteredSubmissions: [ExamSubmission] {
        viewModel.submissions.filter { submission in
            (searchText.isEmpty || submission.username.localizedCaseInsensitiveContains(searchText)) &&
            (statusFilter == nil || submission.status == statusFilter)
        }
        .sorted {
            sortOrder == .ascending ? $0.submissionDate < $1.submissionDate : $0.submissionDate > $1.submissionDate
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    // Search Bar at the top, with padding adjusted to stay at the top
                    SearchBar(text: $searchText)
                        .padding([.horizontal, .top], 16)

                    // Filter and Sort options
                    HStack {
                        FilterPicker(statusFilter: $statusFilter)
                        SortPicker(sortOrder: $sortOrder)
                    }
                    .padding(.horizontal)

                    // Content in ScrollView
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
            .navigationBarTitle("Records", displayMode: .inline)
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
            Text("Exam ID: \(submission.examQuestionId)")
                .font(.subheadline)
            Text("Score: \(submission.score)")
            Text("Status: \(submission.status.capitalized)")
                .foregroundColor(submission.status == "pass" ? .green : .red)
            Text("Submitted: \(formattedDate(submission.submissionDate))")
                .font(.caption)
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
