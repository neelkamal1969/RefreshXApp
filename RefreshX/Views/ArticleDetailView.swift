// ArticleDetailView.swift
import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    let isFavorite: Bool
    let isRead: Bool
    let toggleFavorite: () -> Void
    let toggleRead: () -> Void
    
    @State private var showingFullImage: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with thumbnail
                headerView
                
                // Title and author
                titleAuthorView
                
                // Content
                Text(article.content)
                    .font(.body)
                    .padding(.horizontal)
                
                // Action buttons
                actionButtonsView
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .primary)
                }
            }
        }
        .sheet(isPresented: $showingFullImage) {
            if let image = article.thumbnailImage {
                fullScreenImageView(image)
            }
        }
    }
    
    private var headerView: some View {
        ZStack(alignment: .bottom) {
            if let thumbnailImage = article.thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .onTapGesture {
                        showingFullImage = true
                    }
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
            }
            
            HStack {
                Text(article.type.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(typeColor(for: article.type))
                    .cornerRadius(8)
                
                Spacer()
                
                Text(formattedDate(from: article.dateAdded))
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
    
    private var titleAuthorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.title)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text("By \(article.author)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(isRead ? "Read" : "Unread")
                    .font(.subheadline)
                    .foregroundColor(isRead ? .white : .blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isRead ? Color.gray : Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var actionButtonsView: some View {
        HStack {
            Button(action: toggleFavorite) {
                HStack {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                    Text(isFavorite ? "Unfavorite" : "Favorite")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(isFavorite ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
                .foregroundColor(isFavorite ? .yellow : .primary)
                .cornerRadius(10)
            }
            
            Button(action: toggleRead) {
                HStack {
                    Image(systemName: isRead ? "book.closed" : "book")
                    Text(isRead ? "Mark Unread" : "Mark Read")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(isRead ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(isRead ? .gray : .blue)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private func fullScreenImageView(_ image: UIImage) -> some View {
        VStack {
            HStack {
                Spacer()
                Button("Close") {
                    showingFullImage = false
                }
                .padding()
            }
            
            Spacer()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            
            Spacer()
        }
        .background(Color.black.opacity(0.8))
        .edgesIgnoringSafeArea(.all)
    }
    
    private func typeColor(for focusArea: FocusArea) -> Color {
        switch focusArea {
        case .eye:
            return .blue
        case .back:
            return .green
        case .wrist:
            return .orange
        }
    }
    
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Preview provider with sample data
struct ArticleDetailView_Previews: PreviewProvider {
    static var sampleArticle = Article(
        id: UUID(),
        title: "Eye Health Tips",
        author: "Dr. Lee",
        thumbnailBase64: nil,
        dateAdded: Date(),
        type: .eye,
        content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    )
    
    static var previews: some View {
        NavigationStack {
            ArticleDetailView(
                article: sampleArticle,
                isFavorite: true,
                isRead: false,
                toggleFavorite: {},
                toggleRead: {}
            )
        }
    }
}

                     
