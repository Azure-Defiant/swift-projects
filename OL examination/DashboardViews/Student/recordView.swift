import SwiftUI

struct DropMenu: Identifiable {
    var id = UUID()
    var title: String
}

let drop = [
    DropMenu(title: "Java"),
    DropMenu(title: "Python"),
    DropMenu(title: "Kotlin"),
    DropMenu(title: "Swift"),
    DropMenu(title: "Flutter")
]

struct recordView: View {
    @State private var isDropdownOpen = false

    var body: some View {
        ZStack {
            Color.theme.Uicolor
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text("Scores")
                        .font(.custom("Poppins-Bold", size: 30))
                        .padding(.top, 50) // Adjust the top padding as needed
                        .padding(.leading, 20) // Adjust the leading padding for left margin
                    Spacer() // Keeps the text on the left side
                }
                
                // Move the dropdown menu under the "Scores" text
                VStack {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isDropdownOpen.toggle()
                        }
                    }) {
                        HStack {
                            Text("Select Subject")
                                .foregroundColor(.black)
                                .font(.custom("Poppins-Bold", size: 18))
                            Image(systemName: isDropdownOpen ? "chevron.up" : "chevron.down")
                                .font(.custom("Poppins-Bold", size: 18))
                                .foregroundColor(.black)
                        }
                        .frame(width: 200)
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                    .shadow(radius: 2)

                    if isDropdownOpen {
                        ScrollView {
                            VStack(spacing: 0) { // Remove spacing for cleaner dividers
                                ForEach(drop) { item in
                                    VStack {
                                        Button(action: {
                                            // Handle button tap
                                        }) {
                                            Text(item.title)
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left
                                                .foregroundColor(.black)
                                        }
                                        Divider() // Line separator between each item
                                    }
                                }
                            }
                        }
                        .frame(width: 200, height: 200)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .padding(.top, 10)
                        .offset(y: isDropdownOpen ? 0 : -200) // Add an offset to move the dropdown menu up and down
                    }
                }
                .padding(.top, 20) // Add some padding to move the dropdown menu down
                
                Spacer() // Pushes the content to the top
            }
            .padding()
        }
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        recordView()
    }
}
