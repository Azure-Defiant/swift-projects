import Supabase
import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    // Properties for sign-in
        @Published var signInEmail: String = ""
        @Published var signInPassword: String = ""
        @Published var currentUserEmail: String = ""

        // Properties for sign-up
        @Published var signupUsername: String = ""
        @Published var signUpEmail: String = ""
        @Published var signUpPassword: String = ""

        // Common properties
        @Published var error: String?
        @Published var isLoggedIn = false
        @Published var userRole: String? = nil
    
        @Published var selectedRole: String?
    
        @Published var userRoleId: Int?
       // @Published var navigateToRoleSelection: Bool = false // Ensure this is defined
        @Published var navigateToSignUp: Bool = false
        @Published var shouldNavigateToDashboard: Bool = false
        @Published var selectedDashboard: String? = nil
        @Published var shouldNavigateToRoleSelection: Bool = false
    //navigate their roles into deisgnated dashboard
        @Published var navigateToTeacherDashboard: Bool = false
        @Published var navigateToStudentDashboard: Bool = false
    
    
    // Reference to Supabase client
    private let client = SupabaseManager.shared.client
    
    

    // Public function to update the user's role
    func updateUserRole(email: String, roleId: Int) async throws {
        let response = try await client
            .from("users")
            .update(["role_id": roleId])
            .eq("email", value: email)
            .execute()
        
        print("Role updated successfully: \(response)")
    }
    
    // Update User Metadata Function
    func updateUserMetadata(roleId: Int) {
        Task {
            do {
                let response = try await client
                    .from("users")
                    .update(["role_id": roleId]) // Update the role_id based on selected role
                    .eq("email", value: self.signUpEmail) // Match by email
                    .execute()

                if response.status == 200 {
                    print("User metadata updated successfully with role ID: \(roleId)")
                } else {
                    print("Failed to update user metadata: Status Code: \(response.status)")
                }
            } catch {
                print("Error updating user metadata: \(error.localizedDescription)")
            }
        }
    }
        
        // Async function to handle sign-in
        func signIn() {
            Task {
                do {
                    let session = try await client.auth.signIn(email: signInEmail, password: signInPassword)
                    print("Sign in successful: \(session)")
                    
                    // Directly assign userId from session.user.id
                    let userId = session.user.id
                    
                    // Fetch user role after successful sign-in
                    self.userRole = try await fetchUserRole(userId: userId)
                    
                    DispatchQueue.main.async {
                        self.error = nil
                        self.isLoggedIn = true
                        self.shouldNavigateToDashboard = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                    }
                    print("Sign in failed: \(error.localizedDescription)")
                }
            }
        }
        
        // Async function to handle sign-up
    @MainActor
    func signUp(role: String, completion: @escaping (Bool) -> Void) {
        print("Selected role before signup: \(role)")
        Task {
            do {
                // Sign up the user
                let session = try await client.auth.signUp(email: signUpEmail, password: signUpPassword)
                print("Sign up successful: \(session)")
                
                // Fetch the role
                try await fetchRole(by: role)

                guard let roleId = userRoleId else {
                    print("Failed to retrieve role ID after fetching role")
                    completion(false)
                    return
                }

                // Insert user data
                let response = try await client
                    .from("users")
                    .insert([
                        "username": signupUsername,
                        "email": signUpEmail,
                        "role_id": String(roleId)
                    ])
                    .execute()

                print("User   inserted successfully: \(response)")
                self.error = nil

                // Navigate based on the selected role
                if role == "Teacher" {
                    navigateToTeacherDashboard = true
                } else if role == "Student" {
                    navigateToStudentDashboard = true
                }
                    
                completion(true)

            } catch {
                self.error = error.localizedDescription
                print("Sign up failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // Fetch user role from the database
    func fetchUserRole(userId: UUID) async throws -> String? {
        struct UserResponse: Codable {
            let role_id: Int
        }

        // Fetch role from the 'users' table
        let response = try await client
            .from("users")
            .select("role_id")
            .eq("id", value: userId.uuidString)
            .single() // This should fetch a single record based on the userId
            .execute()

        // Check if the response contains data
        // Assuming response.data is of type Data, you can check for an empty state
        if response.data.isEmpty {
            print("No data found for user ID: \(userId)")
            return nil
        }

        // Decode the user response directly from the Data
        let userResponse = try JSONDecoder().decode(UserResponse.self, from: response.data)

        // Return the role based on the role_id
        switch userResponse.role_id {
            case 1:
                return "Teacher"
            case 2: // Assuming 2 is the ID for Student
                return "Student"
            default:
                print("Unknown role ID: \(userResponse.role_id)")
                return nil
        }
    }
    
    // Additional user management functions (create, update, delete)
    // ...
}
  


extension AuthViewModel {
    @MainActor
    func fetchRole(by role: String) async throws {
        // Fetch role from the roles table
        let roleResponse = try await client
            .from("roles")
            .select("id, role_name")
            .eq("role_name", value: role)
            .limit(1) // Get at most one result
            .execute()

        // Decode the roles data directly from roleResponse.data
        let roles = try JSONDecoder().decode([Role].self, from: roleResponse.data)

        // Ensure there is at least one role and set the userRoleId
        guard let fetchedRole = roles.first else {
            throw NSError(domain: "AuthViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Role not found"])
        }

        // Set the userRoleId property
        self.userRoleId = fetchedRole.id // Ensure userRoleId is the correct type
        self.userRole = fetchedRole.role_name

        // Safely unwrap userRoleId before printing
        if let userRoleId = self.userRoleId {
            print("Fetched role: \(self.userRole ?? "Unknown role"), ID: \(userRoleId)")
        } else {
            print("Fetched role: \(self.userRole ?? "Unknown role"), ID: Not available")
        }
    }
}
        
        
       


