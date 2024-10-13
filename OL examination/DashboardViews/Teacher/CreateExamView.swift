import SwiftUI
import Supabase

struct CreateExamView: View {
    @Environment(\.dismiss) var dismiss
    @State private var examTitle: String = ""
    @State private var questionText: String = ""
    @State private var questionType: String = "multiple-choice"
    @State private var options: [String] = ["", "", "", ""]
    @State private var correctAnswer: String = ""
    @State private var questions: [(String, String, [String], String)] = []

    // Alert state
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Supabase client instance
    let supabaseClient = createSupabaseClient()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Create Exam")
                .font(.largeTitle)
                .padding(.bottom, 20)

            // Exam Title Input
            TextField("Enter exam title", text: $examTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 20)
                .onTapGesture {
                    dismissKeyboard()
                }

            // Question Input
            TextField("Enter question", text: $questionText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
                .onTapGesture {
                    dismissKeyboard()
                }

            // Question Type Picker
            Picker("Question Type", selection: $questionType) {
                Text("Multiple Choice").tag("multiple-choice")
                Text("Identification").tag("identification")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 20)
            .onChange(of: questionType) { _ in
                dismissKeyboard() // Dismiss keyboard when question type changes
            }

            // Multiple Choice Options (Only show if question type is multiple choice)
            if questionType == "multiple-choice" {
                ForEach(0..<4) { index in
                    TextField("Option \(Character(UnicodeScalar(97 + index)!)).", text: $options[index]) // Display as a, b, c, d
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 5)
                        .onTapGesture {
                            dismissKeyboard()
                        }
                }
                // Input for correct answer
                TextField("Correct answer (a, b, c, or d)", text: $correctAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                    .onTapGesture {
                        dismissKeyboard()
                    }
            }

            // Button to Add Question
            Button(action: {
                addQuestion()
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
                        if question.1 == "multiple-choice" {
                            ForEach(question.2.indices, id: \.self) { index in
                                if !question.2[index].isEmpty {
                                    Text("Option \(Character(UnicodeScalar(97 + index)!)): \(question.2[index])")
                                        .font(.subheadline)
                                }
                            }
                        }
                        Text("Correct Answer: \(question.3)")
                    }
                    .padding()
                }
            }

            // Submit Button
            Button(action: {
                Task {
                    await uploadExam()
                }
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // Clear the input fields after adding a question
    private func clearQuestionFields() {
        questionText = ""
        options = ["", "", "", ""]
        correctAnswer = ""
    }

    // Function to add question
    private func addQuestion() {
        dismissKeyboard()

        if questionText.isEmpty {
            alertMessage = "Please enter a question."
            showAlert = true
            return
        }

        if questionType == "multiple-choice" {
            // Check for empty options and correct answer
            if options.contains(where: { $0.isEmpty }) {
                alertMessage = "Please fill in all the options."
                showAlert = true
                return
            }

            if correctAnswer.isEmpty || !"abcd".contains(correctAnswer.lowercased()) {
                alertMessage = "Please enter a valid correct answer (a, b, c, or d)."
                showAlert = true
                return
            }
        }

        // Add the question to the list
        let newQuestion = (questionText, questionType, options, correctAnswer)
        questions.append(newQuestion)
        clearQuestionFields()
    }

    // Function to handle uploading the exam
    private func uploadExam() async {
        dismissKeyboard()

        if examTitle.isEmpty {
            alertMessage = "Please enter an exam title."
            showAlert = true
            return
        }

        if questions.isEmpty {
            alertMessage = "Please add at least one question."
            showAlert = true
            return
        }

        // Get authenticated user's email and fetch their userId (Int64)
        guard let email = supabaseClient.auth.currentUser?.email else {
            alertMessage = "You must be logged in to create an exam."
            showAlert = true
            return
        }

        guard let authenticatedUserID = try? await fetchUserId(byEmail: email) else {
            alertMessage = "Failed to fetch user ID."
            showAlert = true
            return
        }

        print("Uploading exam with userId: \(authenticatedUserID)")

        // Upload exam and questions to backend (Supabase)
        await uploadExamToSupabase(
            title: examTitle,
            questions: questions,
            userId: authenticatedUserID // Now an Int64
        ) { success, error in
            if success {
                // Dismiss view on success
                dismiss()
            } else if let error = error {
               
                alertMessage = "Error uploading exam: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    // Fetch userId (Int64) from Supabase based on email
    private func fetchUserId(byEmail email: String) async throws -> Int64? {
        struct UserResponse: Codable {
            let id: Int64
        }

        do {
            let response = try await supabaseClient
                .from("users")
                .select("id")
                .eq("email", value: email)
                .single()
                .execute()
            
            // Explicitly check if the data is non-empty
            if !response.data.isEmpty {
                let userData = try JSONDecoder().decode(UserResponse.self, from: response.data)
                return userData.id
            } else {
                print("No user found with email: \(email)")
                return nil
            }
        } catch {
            print("Error fetching user ID: \(error.localizedDescription)")
            throw error
        }
    }

    // Function to dismiss the keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    CreateExamView()
}
