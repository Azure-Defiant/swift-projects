import SwiftUI
import Supabase

struct CreateExamView: View {
    @Environment(\.dismiss) var dismiss
    @State private var examTitle: String = ""
    @State private var questionText: String = ""
    @State private var questionType: String = "multiple-choice"
    @State private var options: [String] = Array(repeating: "", count: 4)
    @State private var correctAnswer: String = ""
    @State private var questions: [(String, String, [String], String)] = []
    @State private var showAlert = false
    @State private var alertMessage = ""

    let supabaseClient = createSupabaseClient()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Create Exam")
                .font(.largeTitle)
                .padding(.bottom, 20)

            TextField("Enter exam title", text: $examTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 20)
                .onTapGesture { dismissKeyboard() }

            TextField("Enter question", text: $questionText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
                .onTapGesture { dismissKeyboard() }

            Picker("Question Type", selection: $questionType) {
                Text("Multiple Choice").tag("multiple-choice")
                Text("Identification").tag("identification")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 20)
            .onChange(of: questionType) { _ in dismissKeyboard() }

            if questionType == "multiple-choice" {
                ForEach(0..<4, id: \.self) { index in
                    TextField("Option \(Character(UnicodeScalar(97 + index)!)).", text: $options[index])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 5)
                        .onTapGesture { dismissKeyboard() }
                }
            }

            TextField("Correct answer \(questionType == "multiple-choice" ? "(a, b, c, or d)" : "")", text: $correctAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .padding(.bottom, 10)
                .onTapGesture { dismissKeyboard() }

            Button("Add Question") { addQuestion() }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 20)

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

            Button("Upload Exam") { Task { await uploadExam() } }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

            Spacer()
        }
        .padding()
        .navigationBarTitle("Create Exam", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func clearQuestionFields() {
        questionText = ""
        options = Array(repeating: "", count: 4)
        correctAnswer = ""
    }

    private func addQuestion() {
        dismissKeyboard()

        guard !questionText.isEmpty else {
            alertMessage = "Please enter a question."
            showAlert = true
            return
        }

        if questionType == "multiple-choice" {
            guard !options.contains(where: { $0.isEmpty }) else {
                alertMessage = "Please fill in all the options."
                showAlert = true
                return
            }

            guard !correctAnswer.isEmpty, "abcd".contains(correctAnswer.lowercased()) else {
                alertMessage = "Please enter a valid correct answer (a, b, c, or d)."
                showAlert = true
                return
            }
        } else if questionType == "identification" {
            guard !correctAnswer.isEmpty else {
                alertMessage = "Please enter the correct answer for the identification question."
                showAlert = true
                return
            }
        }

        let newQuestion = (questionText, questionType, options, correctAnswer)
        questions.append(newQuestion)
        clearQuestionFields()
    }

    private func uploadExam() async {
        dismissKeyboard()

        guard !examTitle.isEmpty else {
            alertMessage = "Please enter an exam title."
            showAlert = true
            return
        }

        guard !questions.isEmpty else {
            alertMessage = "Please add at least one question."
            showAlert = true
            return
        }

        guard let email = supabaseClient.auth.currentUser?.email else {
            alertMessage = "You must be logged in to create an exam."
            showAlert = true
            return
        }

        do {
            guard let authenticatedUserID = try await fetchUserId(byEmail: email) else {
                alertMessage = "Failed to fetch user ID."
                showAlert = true
                return
            }

            print("Uploading exam with userId: \(authenticatedUserID)")

            await uploadExamToSupabase(
                title: examTitle,
                questions: questions,
                userId: authenticatedUserID
            ) { success, error in
                if success {
                    dismiss()
                } else if let error = error {
                    alertMessage = "Error uploading exam: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        } catch {
            alertMessage = "Error uploading exam: \(error.localizedDescription)"
            showAlert = true
        }
    }

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

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    CreateExamView()
}
