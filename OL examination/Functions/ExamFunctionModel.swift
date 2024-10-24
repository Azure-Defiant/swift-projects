import Foundation
import Combine
import Supabase

struct Question: Codable, Identifiable {
    let id: Int64
    let questionText: String
    let questionType: String
    var options: [Answer] = []
    
    enum CodingKeys: String, CodingKey {
        case id, questionText = "question_text", questionType = "question_type", options = "exam_answers"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        questionText = try container.decode(String.self, forKey: .questionText)
        questionType = try container.decode(String.self, forKey: .questionType)
        options = try container.decode([Answer].self, forKey: .options)
    }
}

struct Answer: Codable, Identifiable {
    let id: Int64
    let question_id: Int64
    let answer_option: String
    let is_correct: Bool
}

@MainActor
class ExamViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var selectedAnswers: [Int64: String] = [:]
    @Published var isSubmitted = false
    @Published var finalScore: Int = 0
    @Published var finalStatus: String = ""
    @Published var errorMessage: String?

    let examId: Int64
    let userId: Int64
    
    init(examId: Int64, userId: Int64) {
        self.examId = examId
        self.userId = userId
    }
    
    
    // New method: loadExamQuestions
       func loadExamQuestions() async {
           do {
               let fetchedQuestions = try await fetchQuestionsWithAnswers()
               DispatchQueue.main.async {
                   self.questions = fetchedQuestions
               }
           } catch {
               DispatchQueue.main.async {
                   self.errorMessage = "Failed to load exam questions: \(error.localizedDescription)"
                   print("Error details: \(error.localizedDescription)")
               }
           }
       }

    
    func validateSubmissions() -> Bool {
        for question in questions {
            if selectedAnswers[question.id] == nil {
                print("Answer for question ID \(question.id) is missing")
                return false
            }
        }
        return true
    }
    
    
    
    // Submit exam function using BIGINT user ID
    // Improved submit exam function with pre-validation
       func submitExam() async {
           guard validateSubmissions() else {
               DispatchQueue.main.async {
                   self.errorMessage = "Submission validation failed: Not all questions have been answered."
               }
               return
           }

           do {
               let bigIntUserId = try await fetchBigIntUserId()
               guard let userId = bigIntUserId else {
                   return // Error message is already set in fetchBigIntUserId()
               }

               let (score, status) = try await submitExamLogic(userId: userId)
               DispatchQueue.main.async {
                   self.finalScore = score
                   self.finalStatus = status
                   self.isSubmitted = true
               }
           } catch {
               DispatchQueue.main.async {
                   self.errorMessage = "Error submitting exam: \(error)"
                   print("Error during submission: \(error.localizedDescription)")
               }
           }
       }

    // Fetch the BIGINT user ID from the `users` table using email
    func fetchBigIntUserId() async throws -> Int64? {
        guard let email = SupabaseManager.shared.client.auth.currentUser?.email else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated. Please log in."
            }
            return nil
        }

        let response = try await SupabaseManager.shared.client
            .from("users")
            .select("id")
            .eq("email", value: email)
            .single()
            .execute()
        
        print("Response data: \(String(data: response.data, encoding: .utf8) ?? "No data")")
        
        if response.data.isEmpty {
            DispatchQueue.main.async {
                self.errorMessage = "No user data found for this account. Please contact support."
            }
            return nil
        }

        let user = try JSONDecoder().decode(MappedUserResponse.self, from: response.data)
        return user.id
    }

   
       
    private func submitExamLogic(userId: Int64) async throws -> (Int, String) {
        var totalScore = 0
        let passingScore = 5

        // Prepare the submissions array
        let submissions = try await prepareSubmissions(userId: userId, totalScore: &totalScore)
        if submissions.isEmpty {
            self.errorMessage = "No answers to submit."
            return (0, "Failed")
        }

        // Insert the submissions and validate the response
        let response = try await SupabaseManager.shared.client
            .from("submissions")
            .insert(submissions)
            .select("id") // Ensures that some data is returned for validation
            .execute()

        // Check if data is returned and not empty
        if response.data.isEmpty {
            self.errorMessage = "No data returned from the server."
            return (0, "Failed")
        }

        let finalStatus = totalScore >= passingScore ? "Passed" : "Failed"
        return (totalScore, finalStatus)
    }


    private func prepareSubmissions(userId: Int64, totalScore: inout Int) async throws -> [SubmissionInsert] {
        var submissions: [SubmissionInsert] = []
        
        let fetchedQuestions = try await fetchQuestionsWithAnswers()

        for (questionId, submittedAnswer) in selectedAnswers {
            if let question = fetchedQuestions.first(where: { $0.id == questionId }),
               let correctOption = question.options.first(where: { $0.is_correct }) {
                
                let isCorrect = correctOption.answer_option.lowercased() == submittedAnswer.lowercased()
                let score = isCorrect ? 1 : 0
                totalScore += score
                let status = isCorrect ? "pass" : "fail"

                let submission = SubmissionInsert(
                    user_id: userId,
                    exam_question_id: questionId,
                    score: score,
                    status: status,
                    submitted_answer: submittedAnswer,
                    is_correct: isCorrect
                )
                
                submissions.append(submission)
            }
        }

        // Log the prepared submissions for debugging
        print("Prepared Submissions: \(submissions)")
        
        return submissions
    }



    private func fetchQuestionsWithAnswers() async throws -> [Question] {
        let questionsResponse = try await SupabaseManager.shared.client
            .from("exam_questions")
            .select("*, exam_answers!inner(*)")
            .eq("exam_id", value: String(examId))
            .execute()

        return try JSONDecoder().decode([Question].self, from: questionsResponse.data)
    }

    struct SubmissionInsert: Codable {
        let user_id: Int64
        let exam_question_id: Int64
        let score: Int
        let status: String
        let submitted_answer: String
        let is_correct: Bool
    }

    struct MappedUserResponse: Codable {
        let id: Int64?
    }
}
