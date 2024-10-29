import SwiftUI
import Combine
import Foundation

extension String {
    func convertedFromSnakeCaseToCamelCase() -> String {
        let items = self.split(separator: "_")
        let camelCase = items.enumerated().map { index, piece -> String in
            if index == 0 {
                return String(piece).lowercased()
            } else {
                return String(piece).capitalizingFirstLetter()
            }
        }
        return camelCase.joined()
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

struct Student: Identifiable, Codable {
    var id: Int64
    var username: String

    enum CodingKeys: String, CodingKey {
        case id = "student_id"
        case username
    }
}

struct StudentExamRecord: Identifiable, Codable {
    var id = UUID()
    var examTitle: String?
    var totalScore: Int?
    var status: String
    var submissionDate: String?

    enum CodingKeys: String, CodingKey {
      //  case id = "exam_id"
        case examTitle = "exam_title"
        case totalScore = "total_score"
        case status
        case submissionDate = "submission_date"
    }
}

@MainActor
class RecordsViewModel: ObservableObject {
    @Published var students: [Student] = []
    @Published var examRecords: [StudentExamRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client
    private let decoder = JSONDecoder()

    init() {
        decoder.keyDecodingStrategy = .custom { keys in
            guard let lastKey = keys.last else { return AnyKey(stringValue: "") }
            print("Attempting to decode key: \(lastKey.stringValue)")

            if lastKey.stringValue == "student_id" || lastKey.stringValue == "exam_id" || lastKey.stringValue == "exam_title" || lastKey.stringValue == "total_score" || lastKey.stringValue == "submission_date" {
                return AnyKey(stringValue: lastKey.stringValue)
            }

            let adjustedKey = lastKey.stringValue.convertedFromSnakeCaseToCamelCase()
            return AnyKey(stringValue: adjustedKey)
        }
    }

    private struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    func fetchAllStudents() {
           isLoading = true
           Task {
               do {
                   self.students = try await fetchStudents()
                   DispatchQueue.main.async {
                       self.isLoading = false // Ensure this is on the main thread
                   }
               } catch {
                   DispatchQueue.main.async {
                       self.errorMessage = "Failed to fetch students: \(error.localizedDescription)"
                       self.isLoading = false
                   }
               }
           }
       }

    func fetchStudentExamRecords(studentId: Int64, completion: @escaping () -> Void) {
            DispatchQueue.main.async { self.isLoading = true }
            examRecords = [] // Clear records before fetching
            Task {
                do {
                    self.examRecords = try await fetchExamRecords(studentId: studentId)
                    DispatchQueue.main.async {
                        self.isLoading = false // Stop loading after fetch
                        completion()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to fetch exam records: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }

    private func fetchStudents() async throws -> [Student] {
        let response = try await client.rpc("get_all_students").execute()
        print("Debug: Raw server response for fetchStudents - \(String(describing: String(data: response.data, encoding: .utf8)))")
        do {
            let students = try decoder.decode([Student].self, from: response.data)
            print("Decoded Students: \(students)")
            return students
        } catch {
            print("Decoding Error: \(error)")
            printDecodingError(error as! DecodingError)
            throw error
        }
    }

    private func fetchExamRecords(studentId: Int64) async throws -> [StudentExamRecord] {
        let response = try await client.rpc("get_student_exam_records", params: ["student_id_param": studentId]).execute()
        print("Debug: Raw server response for fetchExamRecords - \(String(describing: String(data: response.data, encoding: .utf8)))")
        do {
            let records = try decoder.decode([StudentExamRecord].self, from: response.data)
            print("Decoded Exam Records: \(records)")
            return records
        } catch {
            print("Decoding Error: \(error)")
            printDecodingError(error as! DecodingError)
            throw error
        }
    }

    func printDecodingError(_ error: DecodingError) {
        switch error {
        case .keyNotFound(let key, let context):
            print("Key '\(key.stringValue)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath.map { $0.stringValue }.joined(separator: ", "))
        case .valueNotFound(let type, let context):
            print("Value '\(type)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath.map { $0.stringValue }.joined(separator: ", "))
        case .typeMismatch(let type, let context):
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath.map { $0.stringValue }.joined(separator: ", "))
        case .dataCorrupted(let context):
            print("Data corrupted:", context.debugDescription)
            print("codingPath:", context.codingPath.map { $0.stringValue }.joined(separator: ", "))
        @unknown default:
            print("Unknown decoding error")
        }
    }
}

// exam records view
struct RecordsView: View {
    @StateObject private var viewModel = RecordsViewModel()
    @State private var searchText = ""
    @State private var selectedStudent: Student?
    @State private var isExamRecordsViewActive = false

    var filteredStudents: [Student] {
        viewModel.students.filter { searchText.isEmpty || $0.username.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            List(filteredStudents) { student in
                Button(action: {
                    selectedStudent = student
                    isExamRecordsViewActive = false // Reset navigation state
                    viewModel.fetchStudentExamRecords(studentId: student.id) {
                        isExamRecordsViewActive = true // Trigger navigation after records are fetched
                    }
                }) {
                    Text(student.username)
                        .font(.headline)
                        .padding()
                }
            }
            .searchable(text: $searchText, prompt: "Search by student's username")
            .overlay(loadingOverlay)
            .navigationTitle("Student Records")
            .onAppear(perform: viewModel.fetchAllStudents)
            .background(
                NavigationLink(
                    destination: ExamRecordsView(student: selectedStudent, viewModel: viewModel),
                    isActive: $isExamRecordsViewActive
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage).foregroundColor(.red)
        }
    }
}

// exam view records

struct ExamRecordsView: View {
    let student: Student?
    @ObservedObject var viewModel: RecordsViewModel
    
    var body: some View {
        VStack {
            if let student = student {
                Text("\(student.username)'s Records").font(.headline)
            }
            
            List(viewModel.examRecords) { record in
                VStack(alignment: .leading) {
                    Text("Exam Title: \(record.examTitle ?? "Not Available")").font(.headline)
                    Text("Total Score: \(record.totalScore ?? 0)")
                    Text("Status: \(record.status)").foregroundColor(record.status == "Pass" ? .green : .red)
                    Text("Submission Date: \(record.submissionDate ?? "N/A")").font(.caption)
                }
                .padding()
            }
        }
        .navigationBarTitle("\(student?.username ?? "Student")'s Records", displayMode: .inline)
    }
}

// Make sure viewModel is updated before navigating, so it displays all exam records properly.
struct RecordsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordsView()
    }
}

