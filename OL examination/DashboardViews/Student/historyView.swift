import SwiftUI

struct aExamSubmission: Identifiable {
    let id = UUID()
    var examTitle: String
    var submissionDate: Date
    var score: Int
    var status: String
}

struct historyView: View {
    // Sample data for preview purposes
    let submissions = [
        aExamSubmission(examTitle: "Mathematics Final Exam", submissionDate: Date(), score: 85, status: "Passed"),
        aExamSubmission(examTitle: "History Midterm Exam", submissionDate: Date().addingTimeInterval(-86400 * 30), score: 75, status: "Passed"),
        aExamSubmission(examTitle: "Science Quiz", submissionDate: Date().addingTimeInterval(-86400 * 90), score: 65, status: "Failed")
    ]
    
    var body: some View {
        NavigationView {
            List(submissions) { submission in
                VStack(alignment: .leading, spacing: 10) {
                    Text(submission.examTitle)
                        .font(.headline)
                    Text("Submitted on \(submission.submissionDate, formatter: itemFormatter)")
                        .font(.subheadline)
                    Text("Score: \(submission.score)")
                        .font(.subheadline)
                    Text("Status: \(submission.status)")
                        .foregroundColor(submission.status == "Passed" ? .green : .red)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Exam History")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter
}()

struct historyView_Previews: PreviewProvider {
    static var previews: some View {
        historyView()
    }
}
