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
                .hideKeyboardOnTap()
                
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
                            /*
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
                            
                            // Sign in with Google
                            OAuthButton(
                                provider: .google,
                                action: {
                                    Task {
                                        await authViewModel.signInWithGoogle()
                                    }
                                }
                            )
                            
                            // Sign in with GitHub
                            OAuthButton(
                                provider: .github,
                                action: {
                                    Task {
                                        await authViewModel.signInWithGitHub()
                                    }
                                }
                            )
                            */
                        }
                        .padding(24)
                        .liquidGlass()
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .addDoneButton()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            /*
            .sheet(isPresented: Binding(
                get: { authViewModel.oauthURL != nil },
                set: { if !$0 { authViewModel.clearOAuthURL() } }
            )) {
                if let url = authViewModel.oauthURL {
                    OAuthWebView(url: url) { callbackURL in
                        Task {
                            await authViewModel.handleOAuthCallback(url: callbackURL)
                        }
                    } onCancel: {
                        authViewModel.clearOAuthURL()
                    }
                }
            }
            */
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
                .hideKeyboardOnTap()
                
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
                .scrollDismissesKeyboard(.interactively)
                .addDoneButton()
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

// MARK: - OAuth Button Component
struct OAuthButton: View {
    let provider: OAuthProvider
    let action: () -> Void
    
    private var backgroundColor: Color {
        switch provider {
        case .google:
            return Color.white
        case .github:
            return Color(red: 36/255, green: 41/255, blue: 46/255)  // GitHub dark
        }
    }
    
    private var foregroundColor: Color {
        switch provider {
        case .google:
            return Color.black
        case .github:
            return Color.white
        }
    }
    
    private var iconName: String {
        switch provider {
        case .google:
            return "g.circle.fill"  // SF Symbol fallback
        case .github:
            return "chevron.left.forwardslash.chevron.right"  // SF Symbol fallback
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Provider icon
                Group {
                    switch provider {
                    case .google:
                        // Google "G" logo colors
                        Text("G")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 66/255, green: 133/255, blue: 244/255),   // Blue
                                        Color(red: 234/255, green: 67/255, blue: 53/255),    // Red
                                        Color(red: 251/255, green: 188/255, blue: 5/255),    // Yellow
                                        Color(red: 52/255, green: 168/255, blue: 83/255)     // Green
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    case .github:
                        // GitHub octocat-like icon
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(width: 24, height: 24)
                
                Text("Sign in with \(provider.displayName)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: provider == .google ? 1 : 0)
            )
        }
    }
}

// MARK: - OAuth Web View
/// Wraps ASWebAuthenticationSession for OAuth flow
struct OAuthWebView: UIViewControllerRepresentable {
    let url: URL
    let onCallback: (URL) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> OAuthWebViewController {
        OAuthWebViewController(url: url, onCallback: onCallback, onCancel: onCancel)
    }
    
    func updateUIViewController(_ uiViewController: OAuthWebViewController, context: Context) {}
}

class OAuthWebViewController: UIViewController {
    private let url: URL
    private let onCallback: (URL) -> Void
    private let onCancel: () -> Void
    
    init(url: URL, onCallback: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
        self.url = url
        self.onCallback = onCallback
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAuthSession()
    }
    
    private func startAuthSession() {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "mealgorithm"
        ) { [weak self] callbackURL, error in
            if let error = error as? ASWebAuthenticationSessionError,
               error.code == .canceledLogin {
                self?.onCancel()
                return
            }
            
            if let callbackURL = callbackURL {
                self?.onCallback(callbackURL)
            } else {
                self?.onCancel()
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
}

extension OAuthWebViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? UIWindow()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
