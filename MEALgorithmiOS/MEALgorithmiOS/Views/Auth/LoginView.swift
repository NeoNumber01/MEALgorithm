import SwiftUI
import AuthenticationServices

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.appPrimary.opacity(0.1),
                        Color.appSecondary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: geometry.size.height * 0.1)
                        
                        // Logo / Title
                        VStack(spacing: 12) {
                            Text("🍽️")
                                .font(.system(size: 60))
                            
                            Text("MEALgorithm")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.appPrimary, .appSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("AI-Powered Nutrition Tracking")
                                .foregroundColor(.secondary)
                        }
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Error message
                            if let error = authViewModel.error {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .padding(.horizontal)
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                TextField("you@example.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                SecureField("••••••••", text: $password)
                                    .textContentType(.password)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            
                            // Sign In Button
                            Button {
                                Task {
                                    await authViewModel.signIn(email: email, password: password)
                                }
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.appPrimary, .appSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(authViewModel.isLoading)
                            
                            // Sign Up Link
                            Button {
                                showSignUp = true
                            } label: {
                                Text("Don't have an account? ")
                                    .foregroundColor(.secondary) +
                                Text("Sign Up")
                                    .foregroundColor(.appPrimary)
                                    .fontWeight(.semibold)
                            }
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                                Text("or")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Sign in with Apple
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = authViewModel.generateNonce()
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = authViewModel.sha256(nonce)
                            } onCompletion: { result in
                                Task {
                                    await authViewModel.handleAppleSignIn(result: result)
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(12)
                        }
                        .padding(24)
                        .liquidGlass()
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .onChange(of: showSignUp) { _, _ in
                authViewModel.clearError()
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.appPrimary.opacity(0.1),
                        Color.appSecondary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Create your account to start tracking your nutrition with AI")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Error message
                        if let error = authViewModel.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                        
                        // Form
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            SecureField("Password (min 6 characters)", text: $password)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            Button {
                                Task {
                                    await authViewModel.signUp(
                                        email: email,
                                        password: password,
                                        confirmPassword: confirmPassword
                                    )
                                }
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.appPrimary, .appSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(authViewModel.isLoading)
                        }
                        .padding(24)
                        .liquidGlass()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
