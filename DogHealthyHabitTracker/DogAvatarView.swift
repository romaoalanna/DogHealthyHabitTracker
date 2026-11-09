import SwiftUI

struct DogAvatarView: View {
    var photoData: Data?
    var iconName: String
    var avatarColor: Color
    var size: CGFloat = 60
    
    var body: some View {
        if let data = photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DogTheme.pureWhite, lineWidth: max(2, size * 0.04))
                )
                .shadow(color: Color.black.opacity(0.12), radius: size * 0.1, x: 0, y: 2)
        } else {
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: size, height: size)
                    .shadow(color: avatarColor.opacity(0.3), radius: size * 0.1, x: 0, y: 2)
                
                Image(systemName: iconName)
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}
