import Supabase
import Foundation

// Create Supabase client
func createSupabaseClient() -> SupabaseClient {
    guard let url = URL(string: "https://eylzbrmtbjwhkmhjgggr.supabase.co") else {
        fatalError("Invalid URL")
    }
    return SupabaseClient(supabaseURL: url, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5bHpicm10Ymp3aGttaGpnZ2dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY4NDQ3ODQsImV4cCI6MjA0MjQyMDc4NH0.lMlARKfwI8RoLcGgJ5CEJmymZOT2_w-FgP89IqLlIe4")
}

let supabaseClient = createSupabaseClient()


// Upload Exam structure
struct ExamResponse: Codable {
    let id: Int64
}

struct QuestionResponse: Codable {
    let id: Int64
}

struct AnswerResponse: Codable {
    let id: Int64
}

struct ExamInsert: Codable {
    let title: String
}

struct QuestionInsert: Codable {
    let question_text: String
    let question_type: String
    let exam_id: Int64
    let created_by: Int64
    let correct_answer: String?
}

struct AnswerInsert: Codable {
    let question_id: Int64
    let answer_option: String
    let is_correct: Bool
   // let correct_answer : String
}

// Upload Exam function
func uploadExamToSupabase(
    title: String,
    questions: [(String, String, [String], String)],
    userId: Int64,
    completion: @escaping (Bool, Error?) -> Void
) async {
    do {
        // Step 1: Insert the exam into the 'exams' table
        let examResponse = try await supabaseClient
            .from("exams")
            .insert(ExamInsert(title: title))
            .select()
            .single()
            .execute()

        // Decode the response into ExamResponse
        let examData = try JSONDecoder().decode(ExamResponse.self, from: examResponse.data)
        let examId = examData.id

        // Step 2: Insert questions into 'exam_questions'
        for question in questions {
            let questionText = question.0
            let questionType = question.1
            let options = question.2
            let correctAnswer = question.3

            let questionInsert = QuestionInsert(
                question_text: questionText,
                question_type: questionType,
                exam_id: examId,
                created_by: userId,
                correct_answer: correctAnswer
            )

            let questionResponse = try await supabaseClient
                .from("exam_questions")
                .insert(questionInsert)
                .select()
                .single()
                .execute()

            // Decode the response into QuestionResponse
            let questionData = try JSONDecoder().decode(QuestionResponse.self, from: questionResponse.data)
            let questionId = questionData.id

            // Step 3: If the question is multiple choice, insert the answers into 'exam_answers'
            if questionType == "multiple-choice" {
                for (index, option) in options.enumerated() {
                    // Adjust the logic for determining if an answer is correct
                    let isCorrect = (correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == String(Character(UnicodeScalar(97 + index)!))) // Compare with 'a', 'b', 'c', or 'd'

                    let answerInsert = AnswerInsert(
                        question_id: questionId,
                        answer_option: option,
                        is_correct: isCorrect
                    )

                    // Insert answers into exam_answers table
                    _ = try await supabaseClient
                        .from("exam_answers")
                        .insert(answerInsert)
                        .execute()

                    // Log to check if the answer was inserted correctly
                    print("Inserted answer: \(option), is_correct: \(isCorrect)")
                }
            } else if questionType == "identification" {
                // For identification questions, insert the correct answer as a single answer.
                let answerInsert = AnswerInsert(
                    question_id: questionId,
                    answer_option: correctAnswer,
                    is_correct: true
                )

                _ = try await supabaseClient
                    .from("exam_answers")
                    .insert(answerInsert)
                    .execute()

                // Log to check if the answer was inserted correctly
                print("Inserted identification answer: \(correctAnswer), is_correct: true")
            }
        }

        completion(true, nil)
    } catch {
        print("Error during upload: \(error.localizedDescription)")
        completion(false, error)
    }
}
