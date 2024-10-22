//
//  ExamTakingModel.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/15/24.
//

import Foundation


// Models for questions and submissions





// Make sure you have an Exam struct defined
struct Exam: Identifiable, Codable {
    let id: Int64
    let title: String
    let createdAt: String?
    var description: String?
    // ... other properties as needed
}


// Define the Submission struct
struct Submission: Codable {
    let user_id: Int64
    let exam_question_id: Int64
    let score: Int
    let status: String
    let submitted_answer: String
    let is_correct: Bool
}


struct User: Codable {
    let id: Int64  // BIGINT maps to Int64 in Swift
    let username: String
    let email: String
    let role_id: Int64
    let created_at: String?  // time stamp

}

