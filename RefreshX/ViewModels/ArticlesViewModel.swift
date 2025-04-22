
// ArticlesViewModel.swift
import SwiftUI
import Supabase

@MainActor
class ArticlesViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var favoriteIds: Set<UUID> = []
    @Published var readIds: Set<UUID> = []
    @Published var selectedFocusArea: FocusArea? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    
    // Reference to the AuthViewModel to get userId
    private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    // Method to update the authViewModel reference
    func updateAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    // Computed properties
    var filteredArticles: [Article] {
        if let focusArea = selectedFocusArea {
            return articles.filter { $0.type == focusArea }
        } else {
            return articles
        }
    }
    
    var latestArticles: [Article] {
        // Sort by date and take first 2
        let sorted = filteredArticles.sorted(by: { $0.dateAdded > $1.dateAdded })
        return Array(sorted.prefix(2))
    }
    
    // MARK: - API Functions
    
    func fetchArticles() async {
        isLoading = true
        
        do {
            // Fetch all articles, ordered by date_added descending
            let articles: [Article] = try await supabase
                .from("articles")
                .select()
                .order("date_added", ascending: false)
                .execute()
                .value
            
            self.articles = articles
            print("Fetched \(articles.count) articles")
        } catch {
            // Log error but don't show to user
            print("Warning: Error fetching articles - \(error.localizedDescription)")
            
            // Only show error if debugging
            #if DEBUG
            // Don't show the error alert in production
            #endif
        }
        
        isLoading = false
    }
    
    func fetchFavorites() async {
        guard let userId = getUserId() else { return }
        
        do {
            // Fetch all user favorites
            let favorites: [Favorite] = try await supabase
                .from("favorites")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            favoriteIds = Set(favorites.map { $0.articleId })
            print("Fetched \(favorites.count) favorites")
        } catch {
            // Log the error but don't show it to the user
            print("Warning: Error fetching favorites - \(error.localizedDescription)")
        }
    }
    
    func fetchReadArticles() async {
        guard let userId = getUserId() else { return }
        
        do {
            // Fetch all read articles
            let readArticles: [ReadArticle] = try await supabase
                .from("read_articles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            readIds = Set(readArticles.map { $0.articleId })
            print("Fetched \(readArticles.count) read articles")
        } catch {
            // Log the error but don't show it to the user
            print("Warning: Error fetching read articles - \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite(_ article: Article) async {
        guard let userId = getUserId() else { return }
        
        if isArticleFavorite(article) {
            // Remove from favorites
            do {
                try await supabase
                    .from("favorites")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("article_id", value: article.id.uuidString)
                    .execute()
                
                favoriteIds.remove(article.id)
                print("Removed article from favorites: \(article.title)")
            } catch {
                // Only show this error since it's a user-initiated action
                showUserFacingError(error, message: "Failed to remove from favorites")
            }
        } else {
            // Add to favorites
            do {
                let favorite = Favorite(
                    id: UUID(),
                    userId: userId,
                    articleId: article.id
                )
                
                try await supabase
                    .from("favorites")
                    .insert(favorite)
                    .execute()
                
                favoriteIds.insert(article.id)
                print("Added article to favorites: \(article.title)")
            } catch {
                // Only show this error since it's a user-initiated action
                showUserFacingError(error, message: "Failed to add to favorites")
            }
        }
    }
    
    func toggleRead(_ article: Article) async {
        guard let userId = getUserId() else { return }
        
        if isArticleRead(article) {
            // Remove from read articles
            do {
                try await supabase
                    .from("read_articles")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("article_id", value: article.id.uuidString)
                    .execute()
                
                readIds.remove(article.id)
                print("Marked article as unread: \(article.title)")
            } catch {
                // Only show this error since it's a user-initiated action
                showUserFacingError(error, message: "Failed to mark as unread")
            }
        } else {
            // Add to read articles
            do {
                let readArticle = ReadArticle(
                    id: UUID(),
                    userId: userId,
                    articleId: article.id
                )
                
                try await supabase
                    .from("read_articles")
                    .insert(readArticle)
                    .execute()
                
                readIds.insert(article.id)
                print("Marked article as read: \(article.title)")
            } catch {
                // Only show this error since it's a user-initiated action
                showUserFacingError(error, message: "Failed to mark as read")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func isArticleFavorite(_ article: Article) -> Bool {
        return favoriteIds.contains(article.id)
    }
    
    func isArticleRead(_ article: Article) -> Bool {
        return readIds.contains(article.id)
    }
    
    private func getUserId() -> UUID? {
        guard let userId = authViewModel.userId else {
            print("Warning: User not logged in")
            return nil
        }
        return userId
    }
    
    private func showUserFacingError(_ error: Error, message: String? = nil) {
        let errorMessage = message ?? error.localizedDescription
        print("Error: \(errorMessage) - \(error)")
        self.errorMessage = errorMessage
        self.showError = true
    }
    
    // Use this for background operations where errors should be logged but not shown
    private func logError(_ error: Error, message: String? = nil) {
        let errorMessage = message ?? error.localizedDescription
        print("Error (logged only): \(errorMessage) - \(error)")
    }
}
