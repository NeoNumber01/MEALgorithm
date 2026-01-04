import SwiftUI

extension View {
    /// Adds a "Done" button to the keyboard toolbar to dismiss it
    func addDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.bold)
            }
        }
    }
    
    /// Hides keyboard when tapping outside of text fields
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// Applies a smart zooming effect based on scroll position (Apple Weather style)
    /// scales down and fades slightly when moving off-screen
    func smartZoomEffect() -> some View {
        self
            .scrollTransition(.interactive, axis: .vertical) { content, phase in
                content
                    .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                    .opacity(phase.isIdentity ? 1 : 0.8)
                    .blur(radius: phase.isIdentity ? 0 : 2)
            }
    }
}
