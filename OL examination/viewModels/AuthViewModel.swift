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
      
        @Published var navigateToSignUp: Bool = false
        @Published var shouldNavigateToDashboard: Bool = false
        @Published var selectedDashboard: String? = nil
        @Published var shouldNavigateToRoleSelection: Bool = false
    //navigate their roles into deisgnated dashboard
        @Published var navigateToTeacherDashboard: Bool = false
        @Published var navigateToStudentDashboard: Bool = false
        @Published private var shouldHideBackButton = false

    

    
    
    
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
    @MainActor
    func signIn() {
        Task {
            do {
                let session = try await client.auth.signIn(email: signInEmail, password: signInPassword)
                print("Sign in successful: \(session)")

                // Fetch the user role using the email
                self.userRole = try await fetchUserRole(email: signInEmail)

                DispatchQueue.main.async {
                    self.error = nil
                    self.isLoggedIn = true
                    self.shouldHideBackButton = true
                    
                    // Navigate based on user role
                    if self.userRole == "Teacher" {
                        self.navigateToTeacherDashboard = true
                    } else if self.userRole == "Student" {
                        self.navigateToStudentDashboard = true
                    } else {
                        print("Unknown role: \(self.userRole ?? "nil")")
                    }
                    
                    // Clear sign-in inputs
                    self.signInEmail = ""
                    self.signInPassword = ""
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    print("Sign in failed: \(error.localizedDescription)")
                }
            }
        }
    }
        
    struct UserInsert: Encodable {
        let username: String
        let email: String
        let role_id: Int
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
                let newUser = UserInsert(username: signupUsername, email: signUpEmail, role_id: roleId)

                // Insert user data using the struct
                let response = try await client
                    .from("users")
                    .insert(newUser)
                    .execute()
                
                print("User inserted successfully: \(response)")
                self.error = nil

                self.shouldHideBackButton = true

                
                // Navigate based on the selected role
                if role == "Teacher" {
                    navigateToTeacherDashboard = true
                } else if role == "Student" {
                    navigateToStudentDashboard = true
                }
                
                // Clear sign-up inputs
                self.signupUsername = ""
                self.signUpEmail = ""
                self.signUpPassword = ""
                    
                completion(true)

            } catch {
                self.error = error.localizedDescription
                print("Sign up failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // Fetch user role from the database
    func fetchUserRole(email: String) async throws -> String? {
        struct UserResponse: Codable {
            let role_id: Int
        }

        // Fetch role from the 'users' table
        let response = try await client
            .from("users")
            .select("role_id")
            .eq("email", value: email)
            .single()
            .execute()

        // Check if the response contains data
        if response.data.isEmpty {
            print("No data found for email: \(email)")
            return nil
        }

        // Decode the user response directly from the Data
        let userResponse = try JSONDecoder().decode(UserResponse.self, from: response.data)

        // Return the role based on the role_id
        switch userResponse.role_id {
            case 1:
                return "Teacher"
            case 2:
                return "Student"
            default:
                print("Unknown role ID: \(userResponse.role_id)")
                return nil
        }
    }
    
   
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
        
extension AuthViewModel {
    func getRoleId(from role: String) -> Int? {
        switch role {
        case "Teacher":
            return 1
        case "Student":
            return 2
        default:
            return nil // Handle unknown role if necessary
        }
    }
    
}
       


