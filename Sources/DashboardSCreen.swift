import Foundation
import Velt

struct DashboardScreen: View {
    @State var count: Int = 0
    @State var toggleOn: Bool = false
    @State var textInput: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .start, spacing: 20) {

                Text("Widget Showcase", size: 28, weight: .bold)
                    .foregroundColor(.blue)

                // Counter Section
                counterSection
                Divider()

                // Shapes & Toggles
                shapesSection
                Divider()
                toggleSection
                Divider()
                pressableSection

                Divider()

                // Buttons & Navigation
                buttonsSection
                Divider()
                navigationSection

                SizedBox(height: 50)
            }
            .padding(20)
        }
        .background(Color(r: 0.95, g: 0.95, b: 0.97, a: 1))
    }

    var counterSection: some View {
        VStack(spacing: 12) {
            Text("Counter", size: 18, weight: .semibold)
                .foregroundColor(.gray)
            HStack(spacing: 20) {
                Button("-", bgColor: .red, textColor: .white, fontSize: 24, cornerRadius: 12) {
                    count -= 1
                }
                Text("\(count)", size: 48, weight: .bold)
                    .foregroundColor(.green)
                Button("+", bgColor: .green, textColor: .white, fontSize: 24, cornerRadius: 12) {
                    count += 1
                }
            }
        }
    }

    var shapesSection: some View {
        VStack(spacing: 12) {
            Text("Shapes", size: 18, weight: .semibold)
                .foregroundColor(.gray)
            HStack(spacing: 16) {
                Rectangle(color: .blue, w: 50, h: 50)
                RoundedRectangle(cornerRadius: 10, color: .green)
                    .frame(w: 50, h: 50)
                Circle(color: .red, size: 50)
                Capsule(color: .purple)
                    .frame(w: 70, h: 35)
            }
        }
    }

    var toggleSection: some View {
        VStack(spacing: 12) {
            Text("Toggle Sizes", size: 18, weight: .semibold)
                .foregroundColor(.gray)
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Mini", size: 12)
                    Toggle(isOn: $toggleOn, onColor: .red, size: .large)
                }
                VStack(spacing: 4) {
                    Text("Regular", size: 12)
                    Toggle(isOn: $toggleOn, onColor: .blue, size: .regular)
                }
                VStack(spacing: 4) {
                    Text("Large", size: 12)
                    Toggle(isOn: $toggleOn, onColor: .purple, size: .large)
                }
            }
        }
    }

    var pressableSection: some View {
        VStack(spacing: 12) {
            Text("Pressable / InkWell", size: 18, weight: .semibold)
                .foregroundColor(.gray)
            Pressable(onTap: { print("Tapped!") }, pressedOpacity: 0.5) {
                HStack(spacing: 8) {
                    Circle(color: .orange, size: 30)
                    Text("Tap me - press feedback!", size: 14)
                }
                .padding(12)
                .background(.white)
                .cornerRadius(8)
                .border(.orange, width: 1)
            }
        }
    }

    var buttonsSection: some View {
        VStack(spacing: 12) {
            Text("Button Styles", size: 18, weight: .semibold)
                .foregroundColor(.gray)
            Button("Default Button", bgColor: .blue) {}
            Button("Rounded", bgColor: .green, cornerRadius: 20) {}
            Button("Disabled", bgColor: .gray, isEnabled: false) {}
        }
    }

    var navigationSection: some View {
        VStack(spacing: 12) {
            Text("Navigation", size: 18, weight: .semibold)
                .foregroundColor(.gray)
            HStack(spacing: 12) {
                Button(bgColor: .white, borderColor: .blue, borderWidth: 1) {
                    Router.shared.go("/gallery")
                } label: {
                    Text("Gallery", size: 14, color: .blue)
                }
                Button(bgColor: .white, borderColor: .green, borderWidth: 1) {
                    Router.shared.go("/about")
                } label: {
                    Text("About", size: 14, color: .green)
                }
            }

            // Material 3 Demo Button - Featured!
            Button(
                bgColor: Color(r: 0.38, g: 0.49, b: 0.98, a: 1.0), borderColor: .clear,
                borderWidth: 0
            ) {
                Router.shared.go("/material3")
            } label: {
                HStack(spacing: 8) {
                    Text("✨", size: 18, color: .white)
                    Text("Material 3 Demo", size: 16, color: .white, weight: .semibold)
                }
            }
        }
    }
}
