import SwiftUI

#if DEBUG
struct ContentCanvasPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: 0xC8965A), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Talla Speciality")
                        .font(.system(size: 21, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: 0xF6EFE2))

                    Text("Canvas preview is kept in this small file so Xcode can render it quickly.")
                        .font(.footnote)
                        .foregroundStyle(Color(hex: 0xD7C7AD))
                }
            }

            HStack(spacing: 8) {
                Label("Shop", systemImage: "square.grid.2x2")
                Label("Brew", systemImage: "drop.fill")
                Label("Account", systemImage: "person.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color(hex: 0xC8965A))
        }
        .padding(22)
        .frame(width: 380, alignment: .leading)
        .background(Color(hex: 0x17120C), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ContentCanvasPreview_Previews: PreviewProvider {
    static var previews: some View {
        ContentCanvasPreview()
            .previewDisplayName("Content Canvas")
    }
}
#endif
