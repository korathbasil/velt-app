import Foundation
import Velt

struct Material3DemoScreen: View {
    @State var filterSelected1: Bool = false
    @State var filterSelected2: Bool = true
    @State var filterSelected3: Bool = false
    @State var textInput: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .start, spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Material 3 Design", size: 32, weight: .bold)
                        .foregroundColor(.m3Primary)
                    Text("Expressive UI Components", size: 16, color: .m3OnSurfaceVariant)
                }

                Divider(color: .m3OutlineVariant)

                // Button Variants Section
                buttonSection
                Divider(color: .m3OutlineVariant)

                // Cards Section
                cardsSection
                Divider(color: .m3OutlineVariant)

                // Chips Section
                chipsSection
                Divider(color: .m3OutlineVariant)

                // FABs Section
                fabsSection
                Divider(color: .m3OutlineVariant)

                // List Items Section
                listSection
                Divider(color: .m3OutlineVariant)

                // Text Fields Section
                textFieldSection

                SizedBox(height: 80)
            }
            .padding(24)
        }
        .background(Color(r: 0.98, g: 0.98, b: 1.0, a: 1))
    }

    var buttonSection: some View {
        VStack(alignment: .start, spacing: 16) {
            Text("Buttons", size: 22, weight: .semibold)
                .foregroundColor(.m3OnSurface)

            // Filled Buttons
            VStack(alignment: .start, spacing: 8) {
                Text("Filled Button", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 12) {
                    FilledButton("Primary", bgColor: .m3Primary) {
                        print("Primary tapped")
                    }
                    FilledButton("Secondary", bgColor: .m3Secondary) {
                        print("Secondary tapped")
                    }
                    FilledButton("Tertiary", bgColor: .m3Tertiary) {
                        print("Tertiary tapped")
                    }
                }
            }

            // Outlined Buttons
            VStack(alignment: .start, spacing: 8) {
                Text("Outlined Button", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 12) {
                    OutlinedButton("Outlined") {
                        print("Outlined tapped")
                    }
                    OutlinedButton("Action", borderColor: .m3Tertiary, textColor: .m3Tertiary) {
                        print("Action tapped")
                    }
                }
            }

            // Tonal Buttons
            VStack(alignment: .start, spacing: 8) {
                Text("Tonal Button", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 12) {
                    TonalButton("Tonal") {
                        print("Tonal tapped")
                    }
                    TonalButton(
                        "Action", bgColor: .m3TertiaryContainer, textColor: .m3OnTertiaryContainer
                    ) {
                        print("Tonal Action tapped")
                    }
                }
            }

            // Text & Elevated Buttons
            VStack(alignment: .start, spacing: 8) {
                Text("Text & Elevated", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 12) {
                    TextButton("Text Button") {
                        print("Text tapped")
                    }
                    ElevatedButton("Elevated") {
                        print("Elevated tapped")
                    }
                }
            }

            // Disabled State
            VStack(alignment: .start, spacing: 8) {
                Text("Disabled State", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 12) {
                    FilledButton("Disabled", isEnabled: false) {
                        print("Won't fire")
                    }
                    OutlinedButton("Disabled", isEnabled: false) {
                        print("Won't fire")
                    }
                }
            }
        }
    }

    var cardsSection: some View {
        VStack(alignment: .start, spacing: 16) {
            Text("Cards", size: 22, weight: .semibold)
                .foregroundColor(.m3OnSurface)

            // Elevated Card
            ElevatedCard {
                VStack(alignment: .start, spacing: 8) {
                    Text("Elevated Card", size: 18, weight: .semibold)
                        .foregroundColor(.m3OnSurface)
                    Text("Cards contain content and actions about a single subject.", size: 14)
                        .foregroundColor(.m3OnSurfaceVariant)
                }
            }

            // Filled Card
            FilledCard(bgColor: .m3SecondaryContainer) {
                VStack(alignment: .start, spacing: 8) {
                    Text("Filled Card", size: 18, weight: .semibold)
                        .foregroundColor(.m3OnSecondaryContainer)
                    Text("Filled cards provide subtle separation from the background.", size: 14)
                        .foregroundColor(.m3OnSecondaryContainer)
                }
            }

            // Outlined Card
            OutlinedCard {
                VStack(alignment: .start, spacing: 8) {
                    Text("Outlined Card", size: 18, weight: .semibold)
                        .foregroundColor(.m3OnSurface)
                    Text("Outlined cards have a border to emphasize their edges.", size: 14)
                        .foregroundColor(.m3OnSurfaceVariant)
                }
            }

            // Interactive Card with gradient effect
            Card(elevation: .level2, bgColor: Color(r: 0.93, g: 0.87, b: 1.0, a: 1.0)) {
                VStack(alignment: .start, spacing: 12) {
                    HStack(spacing: 12) {
                        Circle(color: .m3Tertiary, size: 48)
                        VStack(alignment: .start, spacing: 4) {
                            Text("Premium Card", size: 16, weight: .semibold)
                                .foregroundColor(.m3OnTertiaryContainer)
                            Text("With elevated shadow", size: 12)
                                .foregroundColor(.m3OnTertiaryContainer)
                        }
                        Spacer()
                    }
                    Text(
                        "Cards can contain multiple elements and create rich, expressive layouts.",
                        size: 14
                    )
                    .foregroundColor(.m3OnTertiaryContainer)
                }
            }
        }
    }

    var chipsSection: some View {
        VStack(alignment: .start, spacing: 16) {
            Text("Chips", size: 22, weight: .semibold)
                .foregroundColor(.m3OnSurface)

            // Filter Chips
            VStack(alignment: .start, spacing: 8) {
                Text("Filter Chips", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 8) {
                    FilterChip("All", isSelected: $filterSelected1)
                    FilterChip("Active", isSelected: $filterSelected2)
                    FilterChip("Completed", isSelected: $filterSelected3)
                }
            }

            // Input Chips
            VStack(alignment: .start, spacing: 8) {
                Text("Input Chips", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 8) {
                    InputChip("Swift") {
                        print("Removed Swift")
                    }
                    InputChip("Material 3") {
                        print("Removed Material 3")
                    }
                    InputChip("Design", bgColor: .m3PrimaryContainer)
                }
            }

            // Suggestion Chips
            VStack(alignment: .start, spacing: 8) {
                Text("Suggestion Chips", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 8) {
                    SuggestionChip("Send Feedback") {
                        print("Feedback tapped")
                    }
                    SuggestionChip("Help") {
                        print("Help tapped")
                    }
                    SuggestionChip("Settings") {
                        print("Settings tapped")
                    }
                }
            }

            // Custom styled chips
            VStack(alignment: .start, spacing: 8) {
                Text("Custom Chips", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 8) {
                    Chip(
                        "⭐ Featured", bgColor: .m3TertiaryContainer,
                        textColor: .m3OnTertiaryContainer, isSelected: true)
                    Chip("🔥 Trending", bgColor: .m3ErrorContainer, textColor: .m3OnErrorContainer)
                    Chip("✨ New", bgColor: .m3PrimaryContainer, textColor: .m3OnPrimaryContainer)
                }
            }
        }
    }

    var fabsSection: some View {
        VStack(alignment: .start, spacing: 16) {
            Text("Floating Action Buttons", size: 22, weight: .semibold)
                .foregroundColor(.m3OnSurface)

            HStack(spacing: 16) {
                // Small FAB
                VStack(spacing: 8) {
                    FAB("+", size: .small) {
                        print("Small FAB tapped")
                    }
                    Text("Small", size: 12, color: .m3OnSurfaceVariant)
                }

                // Regular FAB
                VStack(spacing: 8) {
                    FAB("+") {
                        print("Regular FAB tapped")
                    }
                    Text("Regular", size: 12, color: .m3OnSurfaceVariant)
                }

                // Large FAB
                VStack(spacing: 8) {
                    FAB("+", size: .large) {
                        print("Large FAB tapped")
                    }
                    Text("Large", size: 12, color: .m3OnSurfaceVariant)
                }
            }

            // Extended FABs
            VStack(alignment: .start, spacing: 12) {
                Text("Extended FABs", size: 14, color: .m3OnSurfaceVariant)
                ExtendedFAB(icon: "✏️", label: "Compose") {
                    print("Compose tapped")
                }
                ExtendedFAB(
                    icon: "➕",
                    label: "Create New",
                    bgColor: .m3TertiaryContainer,
                    textColor: .m3OnTertiaryContainer
                ) {
                    print("Create tapped")
                }
            }

            // Color Variants
            VStack(alignment: .start, spacing: 8) {
                Text("Color Variants", size: 14, color: .m3OnSurfaceVariant)
                HStack(spacing: 12) {
                    FAB("❤️", bgColor: .m3ErrorContainer, textColor: .m3OnErrorContainer) {
                        print("Like tapped")
                    }
                    FAB("⭐", bgColor: .m3TertiaryContainer, textColor: .m3OnTertiaryContainer) {
                        print("Star tapped")
                    }
                    FAB("✓", bgColor: Color(r: 0.2, g: 0.7, b: 0.4, a: 1.0), textColor: .white) {
                        print("Check tapped")
                    }
                }
            }
        }
    }

    var listSection: some View {
        VStack(alignment: .start, spacing: 16) {
            Text("List Items", size: 22, weight: .semibold)
                .foregroundColor(.m3OnSurface)

            Card(elevation: .level1) {
                VStack(spacing: 0) {
                    ListTile(
                        title: "Simple List Item",
                        onTap: { print("Item 1 tapped") }
                    )

                    Divider(color: .m3OutlineVariant, thickness: 1)

                    ListTile(
                        title: "List Item with Subtitle",
                        subtitle: "This is a supporting text",
                        onTap: { print("Item 2 tapped") },
                        leading: { Circle(color: .m3Primary, size: 40) },
                        trailing: { EmptyView() }
                    )

                    Divider(color: .m3OutlineVariant, thickness: 1)

                    ListTile(
                        title: "Three-line Item",
                        subtitle: "Supporting text that is long enough to fill up multiple lines",
                        onTap: { print("Item 3 tapped") },
                        leading: { Circle(color: .m3Tertiary, size: 40) },
                        trailing: {
                            Text("99+", size: 12, color: .m3OnErrorContainer)
                                .padding(6)
                                .background(.m3ErrorContainer)
                                .cornerRadius(12)
                        }
                    )

                    Divider(color: .m3OutlineVariant, thickness: 1)

                    ListTile(
                        title: "Profile Settings",
                        subtitle: "Manage your account",
                        onTap: { print("Settings tapped") },
                        leading: {
                            Circle(color: .m3SecondaryContainer, size: 40)
                        },
                        trailing: {
                            Text(">", size: 20, color: .m3OnSurfaceVariant)
                        }
                    )
                }
            }
        }
    }

    var textFieldSection: some View {
        VStack(alignment: .start, spacing: 16) {
            Text("Text Fields", size: 22, weight: .semibold)
                .foregroundColor(.m3OnSurface)

            // Email
            VStack(alignment: .start, spacing: 4) {
                TextField(
                    label: "Email Address",
                    text: $textInput
                )
                HStack {
                    SizedBox(width: 16)
                    Text("Enter your email address", size: 12, color: .m3OnSurfaceVariant)
                }
            }

            // Password
            VStack(alignment: .start, spacing: 4) {
                TextField(
                    label: "Password",
                    text: $textInput
                )
                HStack {
                    SizedBox(width: 16)
                    Text(
                        "Password must be at least 8 characters", size: 12,
                        color: .m3OnSurfaceVariant)
                }
            }

            // Username
            TextField(
                label: "Username",
                text: .constant("john_doe")
            )

            // Error State
            VStack(alignment: .start, spacing: 4) {
                TextField(
                    label: "Error State",
                    text: $textInput,
                    isError: true
                )
                HStack {
                    SizedBox(width: 16)
                    Text("This field has an error", size: 12, color: .m3Error)
                }
            }
        }
    }
}
