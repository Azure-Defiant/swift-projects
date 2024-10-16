import SwiftUI
import Supabase

struct ExamTakingView: View {
    @State private var questions: [Question] = []
    @State private var selectedAnswers: [Int64: String] = [:] // Maps question_id to the student's selected answer
    @State private var isSubmitted = false
    @State private var errorMessage: String?

    let examId: Int64
    let userId: Int64

    var body: some View {
        NavigationView {
            VStack {
                if isSubmitted {
                    Text("Exam submitted successfully!")
                        .font(.title)
                        .padding()
                } else {
                    if !questions.isEmpty {
                        TabView {
                            ForEach(questions, id: \.id) { question in
                                VStack(alignment: .leading) {
                                    Text(question.questionText)
                                        .font(.headline)
                                        .padding(.bottom, 5)

                                    if question.questionType == "multiple-choice" {
                                        MultipleChoiceView(question: question, selectedAnswers: $selectedAnswers)
                                    } else if question.questionType == "identification" {
                                        IdentificationView(question: question, selectedAnswers: $selectedAnswers)
                                    }
                                }
                                .padding()
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // Sliding effect

                        Button(action: {
                            Task {
                                await submitExam()
                            }
                        }) {
                            Text("Submit Exam")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    } else {
                        Text("Loading questions...")
                            .padding()
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Exam")
            .onAppear {
                Task {
                    if questions.isEmpty {
                        await loadExamQuestions()
                    }
                }
            }
        }
    }

    // Function to fetch exam questions from Supabase
    func loadExamQuestions() async {
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
            questions = fetchedQuestions

        } catch {
            errorMessage = "Failed to load exam questions: \(error.localizedDescription)"
            print("Error loading questions: \(error.localizedDescription)")
        }
    }

    // Function to submit the exam
    func submitExam() async {
        do {
            for question in questions {
                if let answer = selectedAnswers[question.id] {
                    let submissionInsert = SubmissionInsert(
                        user_id: userId,                    // Ensure `userId` is passed correctly
                        exam_question_id: question.id,       // Use Int64 for question IDs
                        submitted_answer: answer,
                        status: "submitted"
                    )

                    _ = try await supabaseClient
                        .from("submissions")
                        .insert(submissionInsert)
                        .execute()
                }
            }
            isSubmitted = true
        } catch {
            errorMessage = "Failed to submit the exam."
            print("Error during submission: \(error.localizedDescription)")
        }
    }
}

struct Question: Codable, Identifiable {
    let id: Int64
    let questionText: String
    let questionType: String
    var options: [Answer] = [] // Change to hold Answer objects

    enum CodingKeys: String, CodingKey {
        case id, questionText = "question_text", questionType = "question_type", options = "exam_answers" // Make sure to match with your select statement
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        questionText = try container.decode(String.self, forKey: .questionText)
        questionType = try container.decode(String.self, forKey: .questionType)
        
        // Decode the options (answers) directly from the "exam_answers" key
        options = try container.decode([Answer].self, forKey: .options)
    }
}

struct Answer: Codable, Identifiable {
    let id: Int64
    let question_id: Int64
    let answer_option: String
    let is_correct: Bool
}

// View for multiple-choice questions with sliding
struct MultipleChoiceView: View {
    var question: Question
    @Binding var selectedAnswers: [Int64: String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(question.options, id: \.id) { option in // Use the Answer directly
                HStack {
                    Text(option.answer_option) // Access answer_option from Answer
                        .padding(.leading, 10)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedAnswers[question.id] = option.answer_option // Set selected answer as answer_option
                    }) {
                        Image(systemName: selectedAnswers[question.id] == option.answer_option ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(10)
            }
        }
    }
}

// View for identification questions when sliding
struct IdentificationView: View {
    var question: Question
    @Binding var selectedAnswers: [Int64: String]

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Type your answer", text: Binding(
                get: { selectedAnswers[question.id, default: ""] },
                set: { selectedAnswers[question.id] = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        }
    }
}

