import GroupActivities
import SwiftUI


struct ChatView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        VStack {
            
            Text("Tetra!").italic().font(.extraLargeTitle)
            
            Text("""
                Welcome to Tetra! \
                This is a space designed for learning, sharing, and focused collaboration. \
                Have fun, exchange ideas, and concentrate on your projects.
                """
            )

            .multilineTextAlignment(.center)
            .padding()
            
            Divider()
        
        }
        .padding(.horizontal)
    }
}
