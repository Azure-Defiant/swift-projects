//
//  ExamFunctionModel.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/21/24.
//




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
    
    func loadExamQuestions() async {
        let supabaseClient = SupabaseManager.shared.client
        do {
            let questionsResponse = try await supabaseClient
                .from("exam_questions")
                .select("""
                    *,
                    exam_answers!inner(*)
                """)
                .eq("exam_id", value: String(examId))
                .execute()
            
            let fetchedQuestions = try JSONDecoder().decode([Question].self, from: questionsResponse.data)
            DispatchQueue.main.async {
                self.questions = fetchedQuestions
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load exam questions: \(error.localizedDescription)"
            }
            print("Error loading questions: \(error.localizedDescription)")
        }
    }
    
    
    //SubmissionResult for decoding responses
    struct SubmissionResult: Codable {
        let id: Int
        let userId: Int
        let examQuestionId: Int
        let score: Int
        let status: String
        let submittedAnswer: String
        let isCorrect: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case examQuestionId = "exam_question_id"
            case score
            case status
            case submittedAnswer = "submitted_answer"
            case isCorrect = "is_correct"
        }
    }


    //submission exam function (dynamic)
  

    class ExamSubmissionManager {
        
        // Data structure to insert a submission
        struct SubmissionInsert: Codable {
            let user_id: Int64
            let exam_question_id: Int64
            let score: Int
            let status: String
            let submitted_answer: String
            let is_correct: Bool
        }

        struct Question: Codable {
            let id: Int64
            let question_text: String
            let question_type: String
            var options: [Answer] = []

            enum CodingKeys: String, CodingKey {
                case id, question_text, question_type, options = "exam_answers"
            }
        }

        struct Answer: Codable {
            let id: Int64
            let question_id: Int64
            let answer_option: String
            let is_correct: Bool
        }

        // Merged function to submit the exam and fetch the user's ID before submission
        func submitExam(
            examId: Int64,
            submittedAnswers: [Int64: String], // Dictionary of question ID to submitted answer
            completion: @escaping (Bool, Int, String?, Error?) -> Void // Bool indicates success, Int is the final score, String is the final status
        ) async {
            // Step 1: Authenticate the user and get user ID
            guard let uuid = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
                DispatchQueue.main.async {
                    completion(false, 0, nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
                }
                return
            }

            do {
                // Fetch the mapped user ID based on UUID
                guard let userId = try await fetchMappedUserId(byUUID: uuid) else {
                    DispatchQueue.main.async {
                        completion(false, 0, nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch mapped user ID."]))
                    }
                    return
                }

                var totalScore = 0
                let passingScore = 5  // Define a passing threshold (can be adjusted)

                // Step 2: Fetch the exam questions and correct answers for comparison
                let questionsResponse = try await SupabaseManager.shared.client
                    .from("exam_questions")
                    .select("""
                        *,
                        exam_answers!inner(*)
                    """)
                    .eq("exam_id", value: String(examId))
                    .execute()

                // Decode the response into the fetched questions
                let fetchedQuestions = try JSONDecoder().decode([Question].self, from: questionsResponse.data)
                
                var submissions: [SubmissionInsert] = []
                
                // Step 3: Step through each submitted answer
                for (questionId, submittedAnswer) in submittedAnswers {
                    // Find the question and the correct answer
                    if let question = fetchedQuestions.first(where: { $0.id == questionId }),
                       let correctOption = question.options.first(where: { $0.is_correct }) {

                        // Step 4: Check if the submitted answer is correct
                        let isCorrect = correctOption.answer_option.lowercased() == submittedAnswer.lowercased()
                        let score = isCorrect ? 1 : 0
                        totalScore += score
                        let status = isCorrect ? "pass" : "fail"

                        // Create the submission entry for each answer
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

                // Step 5: Insert the submissions into the 'submissions' table
                if !submissions.isEmpty {
                    _ = try await SupabaseManager.shared.client
                        .from("submissions")
                        .insert(submissions)
                        .execute()
                }

                // Step 6: Determine the final status
                let finalStatus = totalScore >= passingScore ? "Passed" : "Failed"

                // Step 7: Complete with the total score and final status
                completion(true, totalScore, finalStatus, nil)
                
            } catch {
                print("Error during submission: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, 0, nil, error)
                }
            }
        }
        
        // Helper function to fetch the mapped user ID based on UUID
        private func fetchMappedUserId(byUUID uuid: String) async throws -> Int64? {
            struct MappedUserResponse: Codable {
                let int_id: Int64
            }

            // Query the mapping table to get the BIGINT user_id based on the UUID from Supabase Auth
            let response = try await SupabaseManager.shared.client
                .from("user_mapping")
                .select("int_id")
                .eq("uuid", value: uuid)
                .execute()

            // If no data is found, return nil
            if response.data.isEmpty {
                print("No user mapping found for UUID: \(uuid)")
                return nil
            }

            // Decode the data into the MappedUserResponse struct and return the user ID
            let mappedUserData = try JSONDecoder().decode(MappedUserResponse.self, from: response.data)
            return mappedUserData.int_id
        }
    }

    
    
    

    // Function to handle response data dynamically
    private func handleResponseData(_ data: Data) throws {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if jsonObject is [[String: Any]] {
                // JSON is an array of dictionaries
                let results = try JSONDecoder().decode([SubmissionResult].self, from: data)
                print("Decoded array of results:", results)
            } else if let dictionary = jsonObject as? [String: Any] {
                // JSON is a single dictionary
                print("Received a dictionary:", dictionary)
            }
        } catch {
            print("Failed to decode or handle data: \(error)")
            throw error  // Rethrow to handle the error up the chain
        }
    }


        
        
        
        private func fetchMappedUserId(byUUID uuid: String) async throws -> Int64? {
            struct MappedUserResponse: Codable {
                let int_id: Int64
            }
            
            // Query the mapping table to get the BIGINT user_id based on the UUID from Supabase Auth
            let response = try await SupabaseManager.shared.client
                .from("user_mapping")  // Assuming your mapping table is named 'user_mapping'
                .select("int_id")      // Select the BIGINT user ID column
                .eq("uuid", value: uuid) // Filter by the Supabase Auth UUID
                .execute()
            
            // As response.data is not optional, directly decode it.
            if response.data.isEmpty {
                print("No user mapping found for UUID: \(uuid)")
                return nil
            }
            
            // Decode the data into the MappedUserResponse struct and return the BIGINT user ID
            let mappedUserData = try JSONDecoder().decode(MappedUserResponse.self, from: response.data)
            return mappedUserData.int_id
        }
        
        
        // answer checking
        private func checkAnswerForQuestion(_ questionId: Int64, answer: String) -> Bool {
            guard let question = questions.first(where: { $0.id == questionId }) else {
                return false
            }
            
            if let correctOption = question.options.first(where: { $0.is_correct }) {
                return correctOption.answer_option == answer
            }
            return false
        }
    }

