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
    var id: Int64?
    var examTitle: String?
    var totalScore: Int?
    var status: String
    var submissionDate: String?

    enum CodingKeys: String, CodingKey {
        case id = "exam_id"
        case examTitle = "exam_title"
        case totalScore = "total_score"
        case status
        case submissionDate = "submission_date"
    }
}

class RecordsViewModel: ObservableObject {
    @Published var students: [Student] = []
    @Published var examRecords: [StudentExamRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client
    private let decoder = JSONDecoder()

   
    init() {
           decoder.keyDecodingStrategy = .custom { keys in
               guard let lastKey = keys.last else {
                   fatalError("No keys in the decoding context")
               }
               print("Attempting to decode key: \(lastKey.stringValue)") // Debug print to see what keys are being processed
               if lastKey.stringValue == "student_id" || lastKey.stringValue == "exam_id" {
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
                isLoading = false
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch students: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func fetchStudentExamRecords(studentId: Int64) {
        isLoading = true
        Task {
            do {
                self.examRecords = try await fetchExamRecords(studentId: studentId)
                isLoading = false
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

struct RecordsView: View {
    @StateObject private var viewModel = RecordsViewModel()
    @State private var searchText = ""

    var filteredStudents: [Student] {
        viewModel.students.filter { searchText.isEmpty || $0.username.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            List(filteredStudents) { student in
                Button(action: { viewModel.fetchStudentExamRecords(studentId: student.id) }) {
                    Text(student.username)
                        .font(.headline)
                        .padding()
                }
            }
            .searchable(text: $searchText, prompt: "Search by student's username")
            .overlay(loadingOverlay)
            .navigationTitle("Student Records")
            .onAppear(perform: viewModel.fetchAllStudents)
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

struct ExamRecordsView: View {
    let student: Student
    let records: [StudentExamRecord]

    var body: some View {
        List(records) { record in
            VStack(alignment: .leading) {
                Text("Exam Title: \(record.examTitle ?? "Not Available")").font(.headline)
                Text("Total Score: \(record.totalScore ?? 0)")
                Text("Status: \(record.status)").foregroundColor(record.status == "Pass" ? .green : .red)
                Text("Submission Date: \(record.submissionDate ?? "N/A")").font(.caption)
            }
            .padding()
        }
        .navigationBarTitle("\(student.username)'s Records", displayMode: .inline)
    }
}

struct RecordsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordsView()
    }
}
