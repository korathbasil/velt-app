import Foundation
import Velt

struct AboutScreen: View {

    var body: some View {
        VStack(alignment: .leading) {
            Text("About", size: 32, weight: .bold)
                .padding(20)
            Divider()

            // Impeller Details
            VStack(alignment: .leading) {
                Text("Velt", size: 20, color: .blue, weight: .bold)
                Text(
                    "Powered by Impeller.",
                    size: 16, color: .gray)
            }
            .padding(20)

            Spacer()

            Button("Back") {
                Router.shared.back()
            }
            .padding(20)

        }
        .background(.white)
    }
}
