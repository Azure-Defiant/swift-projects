import Foundation
import Supabase


class ExamFunctions {
    static let shared = ExamFunctions()
    
    private let client = SupabaseClient(supabaseURL: URL(string: "https://eylzbrmtbjwhkmhjgggr.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5bHpicm10Ymp3aGttaGpnZ2dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY4NDQ3ODQsImV4cCI6MjA0MjQyMDc4NH0.lMlARKfwI8RoLcGgJ5CEJmymZOT2_w-FgP89IqLlIe4")
    
    
    
}
    /*   // Function to upload an exam and its questions
     func uploadExam(examTitle: String, questions: [(String, String, [String])], createdById: Int) async throws {
     // Step 1: Insert the exam title into the exams table
     let examResponse = try await client.database.from("exams").insert(["title": examTitle]).execute()
     
     // Ensure the exam was inserted and retrieve the exam ID
     guard let examId = examResponse.data.first?["id"] as? Int else {
     throw NSError(domain: "UploadExamError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create exam."])
     }
     
     // Step 2: Insert each question into the exam_questions table
     for question in questions {
     let questionText = question.0
     let questionType = question.1
     
     // Insert question into the exam_questions table
     _ = try await client.database.from("exam_questions").insert([
     "question_text": questionText,
     "question_type": questionType.lowercased(), // Ensure type matches the database
     "created_by": createdById,
     "exam_id": examId
     ]).execute()
     }
     }
     }
     */

    
