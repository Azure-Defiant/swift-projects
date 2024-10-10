import SwiftUI

struct HomeView: View {
    @State private var isShowingCreateExamView = false
    
    var userName: String = "User"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.black)
                    
                    VStack(alignment: .leading) {
                        Text("Welcome, \(userName)!")
                            .font(.title)
                            .bold()
                        
                        Text("Exam Creator")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.leading, 20)
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    isShowingCreateExamView.toggle()
                }) {
                    Text("Start New Form")
                        .font(.title2)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.leading, 20)
                .padding(.top, 150)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .sheet(isPresented: $isShowingCreateExamView) {
            CreateExamView()
                .transition(.move(edge: .bottom)) // Slide from the bottom
                .animation(.easeInOut, value: isShowingCreateExamView)
        }
    }
}

struct CreateExamView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var examTitle: String = ""
    @State private var questionText: String = ""
    @State private var questionType: String = "Multiple Choice"
    @State private var options: [String] = ["", "", "", ""] // For multiple-choice options
    @State private var questions: [(String, String, [String])] = [] // Stores (question, type, options)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Create Exam")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            // Exam Title Input
            TextField("Enter exam title", text: $examTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 20)
            
            // Question Input
            TextField("Enter question", text: $questionText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
            
            // Question Type Picker
            Picker("Question Type", selection: $questionType) {
                Text("Multiple Choice").tag("Multiple Choice")
                Text("Identification").tag("Identification")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 20)
            
            // Multiple Choice Options (Only show if question type is multiple choice)
            if questionType == "Multiple Choice" {
                ForEach(0..<4) { index in
                    TextField("Option \(index + 1)", text: $options[index])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 5)
                }
            }
            
            // Button to Add Question
            Button(action: {
                let newQuestion = (questionText, questionType, options)
                questions.append(newQuestion)
                clearQuestionFields()
            }) {
                Text("Add Question")
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            
            // Display Added Questions
            List {
                ForEach(questions, id: \.0) { question in
                    VStack(alignment: .leading) {
                        Text("Question: \(question.0)")
                        Text("Type: \(question.1)")
                        if question.1 == "Multiple Choice" {
                            ForEach(question.2, id: \.self) { option in
                                if !option.isEmpty {
                                    Text("Option: \(option)")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Submit Button
            Button(action: {
                uploadExam()
                dismiss()
            }) {
                Text("Upload Exam")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Create Exam", displayMode: .inline)
    }
    
    // Clear the input fields after adding a question
    private func clearQuestionFields() {
        questionText = ""
        options = ["", "", "", ""]
    }
    
    // Function to handle uploading the exam
    private func uploadExam() {
        // Upload exam and questions to backend (e.g., Supabase)
        print("Uploading exam titled '\(examTitle)' with questions: \(questions)")
        // Add logic to upload the data to your database
    }
}

#Preview {
    HomeView()
}


// practice another commit
