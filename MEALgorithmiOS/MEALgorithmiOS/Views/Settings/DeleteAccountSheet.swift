import SwiftUI

/// Sheet for confirming account deletion with password verification
struct DeleteAccountSheet: View {
    @Binding var password: String
    @Binding var isLoading: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var isPasswordFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Warning Icon
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 20)
                    
                    // Title & Description
                    VStack(spacing: 12) {
                        Text("Delete Your Account")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("This will permanently delete your account and all associated data including meals, preferences, and AI recommendations.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your password to confirm")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .focused($isPasswordFocused)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if let error = authViewModel.error {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            HapticManager.shared.impact(style: .heavy)
                            onConfirm()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Delete My Account")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(password.isEmpty || isLoading ? Color.gray.opacity(0.5) : Color.red)
                            )
                        }
                        .disabled(password.isEmpty || isLoading)
                        
                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.title3)
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                authViewModel.clearError()
                isPasswordFocused = true
            }
            .animation(.easeInOut(duration: 0.2), value: authViewModel.error)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isLoading)
    }
}

#Preview {
    DeleteAccountSheet(
        password: .constant(""),
        isLoading: .constant(false),
        onConfirm: {},
        onCancel: {}
    )
    .environmentObject(AuthViewModel())
}
