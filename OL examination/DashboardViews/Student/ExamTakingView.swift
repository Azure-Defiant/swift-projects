import SwiftUI

struct ExamTakingView: View {
    @StateObject private var viewModel: ExamViewModel
    @State private var showConfirmationDialog = false  // State for showing confirmation dialog

    // Accept ExamHide as ObservedObject and initialize ExamViewModel with it
    init(examId: Int64, userId: Int64, examHide: ExamHide) {
        _viewModel = StateObject(wrappedValue: ExamViewModel(examId: examId, userId: userId, examHide: examHide))
    }

    // Computed property to check if all questions are answered
    private var allQuestionsAnswered: Bool {
        !viewModel.questions.isEmpty && viewModel.questions.allSatisfy { question in
            viewModel.selectedAnswers[question.id] != nil
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isSubmitted {
                    Text("Exam submitted successfully!")
                        .font(.title)
                        .padding()
                } else {
                    examContent
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Exam")
            .onAppear {
                Task {
                    await viewModel.loadExamQuestions()
                }
            }
        }
    }

    // Exam Content with Questions and Submit Button
    private var examContent: some View {
        VStack {
            if !viewModel.questions.isEmpty {
                TabView {
                    ForEach(viewModel.questions, id: \.id) { question in
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(question.questionText)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                    .foregroundColor(.primary)
                                
                                if question.questionType == "multiple-choice" {
                                    MultipleChoiceView(question: question, selectedAnswers: $viewModel.selectedAnswers)
                                } else if question.questionType == "identification" {
                                    IdentificationView(question: question, selectedAnswers: $viewModel.selectedAnswers)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                if allQuestionsAnswered {
                    submitButton
                }
            } else {
                Text("Loading questions...")
                    .padding()
            }
        }
    }

    // Submit Button with Confirmation Dialog
    private var submitButton: some View {
        Button(action: {
            showConfirmationDialog = true  // Show confirmation dialog
        }) {
            Text("Submit Exam")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(color: .blue.opacity(0.4), radius: 5, x: 0, y: 2)
        }
        .padding()
        .alert(isPresented: $showConfirmationDialog) {
            Alert(
                title: Text("Submit Exam"),
                message: Text("Are you sure you want to submit your answers?"),
                primaryButton: .destructive(Text("Submit")) {
                    Task {
                        await viewModel.submitExam()  // Submit the exam
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct MultipleChoiceView: View {
    var question: Question
    @Binding var selectedAnswers: [Int64: String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(question.options, id: \.id) { option in
                HStack {
                    Text(option.answer_option)
                        .padding(.leading, 10)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedAnswers[question.id] = option.answer_option  // Set selected answer
                    }) {
                        Image(systemName: selectedAnswers[question.id] == option.answer_option ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                .padding(.bottom, 5)
            }
        }
    }
}

struct IdentificationView: View {
    var question: Question
    @Binding var selectedAnswers: [Int64: String]
    
    @State private var answer: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Type your answer", text: $answer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                .onChange(of: answer) { newValue in
                    selectedAnswers[question.id] = newValue  // Update selected answer
                }
        }
        .onAppear {
            answer = selectedAnswers[question.id, default: ""]
        }
    }
}
