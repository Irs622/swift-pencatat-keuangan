import SwiftUI

struct GlassModifier: ViewModifier {
    var opacity: Double = 0.2
    var blurRadius: CGFloat = 20
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
                    .background(
                        BlurLayer(style: .systemThinMaterialDark) // Using a custom blur helper
                            .cornerRadius(cornerRadius)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
    }
}

// UIKit Visual Effect View integration for better blur control
struct BlurLayer: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

extension View {
    func glassCard(opacity: Double = 0.2, blurRadius: CGFloat = 20, cornerRadius: CGFloat = 24) -> some View {
        self.modifier(GlassModifier(opacity: opacity, blurRadius: blurRadius, cornerRadius: cornerRadius))
    }
}

// Preview provider for Glass Card components
struct GlassCards_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("SmartExpense AI")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Monthly Savings")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text("$2,450.00")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                        Text("Income")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard()
                    
                    VStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                        Text("Expense")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard()
                }
                .padding(.horizontal)
                .foregroundColor(.white)
            }
        }
    }
}
