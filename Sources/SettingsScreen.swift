import Foundation
import Velt

struct SettingsScreen: View {
    @State var showFPS: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            Text("Settings", size: 32, weight: .bold)
                .padding(20)
            Divider()

            Text("Feature", size: 20, color: .blue)
                .padding(20)

            Spacer()

            Button("Back") {
                Router.shared.back()
            }
            .padding(30)

        }
        .background(.white)
    }
}
