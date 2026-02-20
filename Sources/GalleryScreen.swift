import Foundation
import Velt

struct GalleryScreen: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("Gallery", size: 32, weight: .bold)
                .padding(20)

            Divider()
            Grid(columns: 2) {
                // Demo Grid Items
                VStack {
                    Image("Assets/Images/100.jpg")
                        .frame(w: 150, h: 150)
                        .cornerRadius(10)
                    Text("Item 1", size: 14)
                }
                .padding(10)

                VStack {
                    Image("Assets/Images/test.jpeg")
                        .frame(w: 150, h: 150)
                        .cornerRadius(10)
                    Text("Item 2", size: 14)
                }
                .padding(10)

                VStack {
                    Image("Assets/Images/test.jpeg")
                        .frame(w: 150, h: 150)
                        .cornerRadius(10)
                    Text("Item 3", size: 14)
                }
                .padding(10)

                VStack {
                    Image("Assets/Images/image.png")
                        .frame(w: 150, h: 150)
                        .cornerRadius(10)
                    Text("Item 4", size: 14)
                }
                .padding(10)
            }

            Spacer()

            Button("Back") {
                Router.shared.back()
            }
            .padding(20)
        }
        .background(.white)
    }
}
