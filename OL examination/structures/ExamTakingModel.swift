//
//  ExamTakingModel.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/15/24.
//

import Foundation


// Models for questions and submissions


struct SubmissionInsert: Codable {
    let user_id: Int64
    let exam_question_id: Int64
    let submitted_answer: String
    let status: String
}

// Make sure you have an Exam struct defined
struct Exam: Identifiable, Codable {
    let id: Int64
    let title: String
    let createdAt: String?
    var description: String?
    // ... other properties as needed
}
