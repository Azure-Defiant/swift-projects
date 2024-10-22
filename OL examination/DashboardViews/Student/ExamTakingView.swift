import SwiftUI

struct ExamTakingView: View {
    @StateObject var viewModel: ExamViewModel  // Correctly using StateObject here.

    init(examId: Int64, userId: Int64) {
        _viewModel = StateObject(wrappedValue: ExamViewModel(examId: examId, userId: userId))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isSubmitted {
                    Text("Exam submitted successfully!")
                        .font(.title)
                        .padding()
                } else {
                    if !viewModel.questions.isEmpty {
                        TabView {
                            ForEach(viewModel.questions, id: \.id) { question in
                                VStack(alignment: .leading) {
                                    Text(question.questionText)
                                        .font(.headline)
                                        .padding(.bottom, 5)
                                    
                                    if question.questionType == "multiple-choice" {
                                        MultipleChoiceView(question: question, selectedAnswers: $viewModel.selectedAnswers)
                                    } else if question.questionType == "identification" {
                                        IdentificationView(question: question, selectedAnswers: $viewModel.selectedAnswers)
                                    }
                                }
                                .padding()
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        
                        Button(action: {
                            Task {
                                await viewModel.submitExam()
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
}


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

struct IdentificationView: View {
    var question: Question
    @Binding var selectedAnswers: [Int64: String]
    
    @State private var answer: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Type your answer", text: $answer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: answer) { newValue in
                    // Update the selected answer in the binding
                    selectedAnswers[question.id] = newValue
                }
        }
        .onAppear {
            // Initialize the text field with the current value from selectedAnswers
            answer = selectedAnswers[question.id, default: ""]
        }
    }
}


#Preview {
    ExamTakingView(examId: 1, userId: 1)
}
