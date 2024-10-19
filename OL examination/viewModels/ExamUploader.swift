import Supabase
import Foundation

class ExamUploader {
    
    // Assuming these are correctly defined to match your database schema
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
        let correct_answer: String? // Add this field here if needed
    }

    struct AnswerInsert: Codable {
        let question_id: Int64
        let answer_option: String
        let is_correct: Bool
    }
    
    // The function to upload the exam
    func uploadExam(
        title: String,
        questions: [(String, String, [String], String)],
        userId: Int64,
        completion: @escaping (Bool, Error?) -> Void
    ) async {
        do {
            // Step 1: Insert the exam into the 'exams' table
            let examResponse = try await SupabaseManager.shared.client
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
                    correct_answer: correctAnswer // Store the correct answer directly if necessary
                )

                let questionResponse = try await SupabaseManager.shared.client
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
                        let correctAnswerIndex = correctAnswer.lowercased()
                        let isCorrect = (correctAnswerIndex == String(UnicodeScalar(97 + index)!)) // Check if answer matches 'a', 'b', 'c', 'd'

                        let answerInsert = AnswerInsert(
                            question_id: questionId,
                            answer_option: option,
                            is_correct: isCorrect
                        )

                        // Insert answers into exam_answers table
                        _ = try await SupabaseManager.shared.client
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

                    _ = try await SupabaseManager.shared.client
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
}
