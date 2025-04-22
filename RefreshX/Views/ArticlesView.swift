// ArticlesView.swift
import SwiftUI

struct ArticlesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ArticlesViewModel
    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var showFavoritesOnly = false
    @State private var showReadOnly = false
    @State private var selectedSortOption = SortOption.newest
    @State private var showToast = false
    @State private var toastMessage = ""
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case alphabetical = "A to Z"
        
        var id: String { self.rawValue }
    }
    
    init() {
        let tempAuthVM = AuthViewModel()
        _viewModel = StateObject(wrappedValue: ArticlesViewModel(authViewModel: tempAuthVM))
        
        // Fix for navigation bar visibility
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                    
                    // Filter options bar
                    filterOptionsBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    // Active filters info bar with clear option
                    if showFavoritesOnly || showReadOnly || viewModel.selectedFocusArea != nil {
                        activeFiltersBar
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Latest Articles Section
                            if searchText.isEmpty && !showFavoritesOnly && !showReadOnly {
                                latestArticlesSection
                            }
                            
                            // Section Title with Filter/Sort options
                            sectionTitleWithOptions
                            
                            // All Articles Grid/List
                            articlesGrid
                                .padding(.bottom, 100) // Extra padding to avoid tab bar overlap
                        }
                    }
                    .refreshable {
                        await viewModel.fetchArticles()
                        await viewModel.fetchFavorites()
                        await viewModel.fetchReadArticles()
                    }
                }
            }
            .navigationTitle("Articles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showFilterSheet = true }) {
                            Label("Filter", systemImage: "slider.horizontal.3")
                                .labelStyle(.iconOnly)
                                .foregroundColor(.blue)
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSortSheet
            }
            .task {
                if viewModel.articles.isEmpty {
                    viewModel.updateAuthViewModel(authViewModel)
                    await viewModel.fetchArticles()
                    await viewModel.fetchFavorites()
                    await viewModel.fetchReadArticles()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    ToastView(message: toastMessage)
                        .padding(.bottom, 90) // Positioned above tab bar
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showToast = false
                                }
                            }
                        }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // NEW: Active filters bar with clear buttons
    private var activeFiltersBar: some View {
        HStack {
            Text("Active filters:")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            if viewModel.selectedFocusArea != nil {
                FilterPill(
                    label: viewModel.selectedFocusArea?.rawValue.capitalized ?? "",
                    color: typeColor(for: viewModel.selectedFocusArea!),
                    onRemove: {
                        viewModel.selectedFocusArea = nil
                    }
                )
            }
            
            if showFavoritesOnly {
                FilterPill(
                    label: "Favorites",
                    color: .yellow,
                    icon: "star.fill",
                    onRemove: {
                        showFavoritesOnly = false
                    }
                )
            }
            
            if showReadOnly {
                FilterPill(
                    label: "Read",
                    color: .green,
                    icon: "book.fill",
                    onRemove: {
                        showReadOnly = false
                    }
                )
            }
            
            Spacer()
            
            // Clear all filters button
            Button(action: {
                withAnimation {
                    viewModel.selectedFocusArea = nil
                    showFavoritesOnly = false
                    showReadOnly = false
                }
                showToastFor("All filters cleared")
            }) {
                Text("Clear All")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6).opacity(0.7))
        .cornerRadius(8)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            TextField("Search articles", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(.primary)
                .accentColor(.blue)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 4)
                }
                .transition(.move(edge: .trailing))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(searchText.isEmpty ? 0 : 0.3), lineWidth: 1)
        )
        .animation(.easeInOut, value: searchText)
    }
    
    private var filterOptionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Filter by Category
                Menu {
                    Button("All Categories") {
                        viewModel.selectedFocusArea = nil
                    }
                    
                    Divider()
                    
                    ForEach(FocusArea.allCases, id: \.self) { focusArea in
                        Button(focusArea.rawValue.capitalized) {
                            viewModel.selectedFocusArea = focusArea
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedFocusArea?.rawValue.capitalized ?? "All Categories")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.selectedFocusArea == nil ? Color(.systemGray6) : Color.blue.opacity(0.2))
                    .foregroundColor(viewModel.selectedFocusArea == nil ? .primary : .blue)
                    .cornerRadius(8)
                }
                
                // Filter by Favorites
                Button(action: {
                    showFavoritesOnly.toggle()
                    if showFavoritesOnly {
                        showReadOnly = false
                        showToastFor("Showing favorites only")
                    } else {
                        showToastFor("Showing all articles")
                    }
                }) {
                    HStack {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                        Text("Favorites")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showFavoritesOnly ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                    .foregroundColor(showFavoritesOnly ? .yellow : .primary)
                    .cornerRadius(8)
                }
                
                // Filter by Read
                Button(action: {
                    showReadOnly.toggle()
                    if showReadOnly {
                        showFavoritesOnly = false
                        showToastFor("Showing read articles only")
                    } else {
                        showToastFor("Showing all articles")
                    }
                }) {
                    HStack {
                        Image(systemName: showReadOnly ? "book.fill" : "book")
                        Text("Read")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showReadOnly ? Color.green.opacity(0.2) : Color(.systemGray6))
                    .foregroundColor(showReadOnly ? .green : .primary)
                    .cornerRadius(8)
                }
                
                // Sort Options
                Menu {
                    Picker("Sort By", selection: $selectedSortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Sort")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var latestArticlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Latest Articles")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.filteredArticles.isEmpty {
                        ForEach(0..<2, id: \.self) { _ in
                            ModernLatestArticleSkeleton()
                        }
                    } else {
                        ForEach(viewModel.latestArticles) { article in
                            NavigationLink(destination: ArticleDetailView(
                                article: article,
                                isFavorite: viewModel.isArticleFavorite(article),
                                isRead: viewModel.isArticleRead(article),
                                toggleFavorite: {
                                    Task {
                                        await viewModel.toggleFavorite(article)
                                        showToastFor(viewModel.isArticleFavorite(article) ?
                                                    "Added to favorites" : "Removed from favorites")
                                    }
                                },
                                toggleRead: {
                                    Task {
                                        await viewModel.toggleRead(article)
                                        showToastFor(viewModel.isArticleRead(article) ?
                                                    "Marked as read" : "Marked as unread")
                                    }
                                }
                            )) {
                                ModernLatestArticleCard(
                                    article: article,
                                    isFavorite: viewModel.isArticleFavorite(article),
                                    isRead: viewModel.isArticleRead(article),
                                    toggleFavorite: {
                                        Task {
                                            await viewModel.toggleFavorite(article)
                                            showToastFor(viewModel.isArticleFavorite(article) ?
                                                        "Added to favorites" : "Removed from favorites")
                                        }
                                    },
                                    toggleRead: {
                                        Task {
                                            await viewModel.toggleRead(article)
                                            showToastFor(viewModel.isArticleRead(article) ?
                                                        "Marked as read" : "Marked as unread")
                                        }
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 260)
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    private var sectionTitleWithOptions: some View {
        HStack {
            Text(sectionTitle)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
            
            // Only show "View All" button when filters are active
            if showFavoritesOnly || showReadOnly {
                Button(action: {
                    withAnimation {
                        showFavoritesOnly = false
                        showReadOnly = false
                    }
                    showToastFor("Viewing all articles")
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    private var sectionTitle: String {
        if showFavoritesOnly {
            return "Favorite Articles"
        } else if showReadOnly {
            return "Read Articles"
        } else if viewModel.selectedFocusArea != nil {
            return "\(viewModel.selectedFocusArea!.rawValue.capitalized) Articles"
        } else {
            return "All Articles"
        }
    }
    
    private var articlesGrid: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredSortedArticles) { article in
                NavigationLink(destination: ArticleDetailView(
                    article: article,
                    isFavorite: viewModel.isArticleFavorite(article),
                    isRead: viewModel.isArticleRead(article),
                    toggleFavorite: {
                        Task {
                            await viewModel.toggleFavorite(article)
                            showToastFor(viewModel.isArticleFavorite(article) ?
                                         "Added to favorites" : "Removed from favorites")
                        }
                    },
                    toggleRead: {
                        Task {
                            await viewModel.toggleRead(article)
                            showToastFor(viewModel.isArticleRead(article) ?
                                         "Marked as read" : "Marked as unread")
                        }
                    }
                )) {
                    ModernArticleCard(
                        article: article,
                        isFavorite: viewModel.isArticleFavorite(article),
                        isRead: viewModel.isArticleRead(article)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .overlay {
            if filteredSortedArticles.isEmpty && !viewModel.isLoading {
                emptyStateView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(emptyStateMessage)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if showFavoritesOnly || showReadOnly || viewModel.selectedFocusArea != nil {
                Button(action: {
                    withAnimation {
                        viewModel.selectedFocusArea = nil
                        showFavoritesOnly = false
                        showReadOnly = false
                    }
                }) {
                    Text("Show All Articles")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    private var emptyStateIcon: String {
        if showFavoritesOnly {
            return "star.slash"
        } else if showReadOnly {
            return "book.closed"
        } else if !searchText.isEmpty {
            return "magnifyingglass"
        } else {
            return "doc.text"
        }
    }
    
    private var emptyStateMessage: String {
        if showFavoritesOnly {
            return "No favorite articles yet\nTap the star icon to add favorites"
        } else if showReadOnly {
            return "No read articles yet\nArticles you've read will appear here"
        } else if !searchText.isEmpty {
            return "No articles match your search"
        } else {
            return "No articles available"
        }
    }
    
    private var filterSortSheet: some View {
        NavigationView {
            List {
                Section("Filter Articles") {
                    // Focus Area
                    Picker("Category", selection: $viewModel.selectedFocusArea) {
                        Text("All Categories").tag(nil as FocusArea?)
                        ForEach(FocusArea.allCases, id: \.self) { area in
                            Text(area.rawValue.capitalized).tag(area as FocusArea?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Favorites
                    Toggle("Favorites Only", isOn: $showFavoritesOnly)
                        .onChange(of: showFavoritesOnly) { newValue in
                            if newValue {
                                showReadOnly = false
                            }
                        }
                        .tint(.blue)
                    
                    // Read status
                    Toggle("Read Articles Only", isOn: $showReadOnly)
                        .onChange(of: showReadOnly) { newValue in
                            if newValue {
                                showFavoritesOnly = false
                            }
                        }
                        .tint(.blue)
                }
                
                Section("Sort By") {
                    Picker("Sort Order", selection: $selectedSortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilterSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.selectedFocusArea = nil
                        showFavoritesOnly = false
                        showReadOnly = false
                        selectedSortOption = .newest
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var filteredSortedArticles: [Article] {
        // First, apply search filter
        var results = viewModel.filteredArticles
        
        if !searchText.isEmpty {
            results = results.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.author.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply favorites filter if selected
        if showFavoritesOnly {
            results = results.filter { viewModel.isArticleFavorite($0) }
        }
        
        // Apply read status filter if selected
        if showReadOnly {
            results = results.filter { viewModel.isArticleRead($0) }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .newest:
            return results.sorted(by: { $0.dateAdded > $1.dateAdded })
        case .oldest:
            return results.sorted(by: { $0.dateAdded < $1.dateAdded })
        case .alphabetical:
            return results.sorted(by: { $0.title < $1.title })
        }
    }
    
    // Helper function for focus area colors
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
    
    // Helper function to show toast messages
    private func showToastFor(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// New component: Active filter pill
struct FilterPill: View {
    let label: String
    let color: Color
    var icon: String? = nil
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(color)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

// Toast view for feedback messages
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
            )
            .foregroundColor(.primary)
            .font(.subheadline)
            .fontWeight(.medium)
    }
}

struct ModernLatestArticleCard: View {
    let article: Article
    let isFavorite: Bool
    let isRead: Bool
    let toggleFavorite: () -> Void
    let toggleRead: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail with overlay
            ZStack(alignment: .bottomLeading) {
                if let thumbnailImage = article.thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                } else {
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [.blue.opacity(0.7), .blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 150)
                        
                        Image(systemName: "book")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    }
                }
                
                // Category pill
                Text(article.type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(12)
            }
            .overlay(alignment: .topTrailing) {
                // Status badges
                HStack(spacing: 8) {
                    Button(action: toggleRead) {
                        Image(systemName: isRead ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isRead ? .green : .white)
                            .font(.system(size: 20))
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .yellow : .white)
                            .font(.system(size: 20))
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(article.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(formattedDate(from: article.dateAdded))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(width: 230)
    }
    
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ModernArticleCard: View {
    let article: Article
    let isFavorite: Bool
    let isRead: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack(alignment: .bottomLeading) {
                if let thumbnailImage = article.thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                } else {
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [typeColor(for: article.type).opacity(0.7), typeColor(for: article.type).opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 120)
                        
                        Image(systemName: focusAreaIcon(for: article.type))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                }
                
                // Status indicators overlay
                HStack(spacing: 4) {
                    // Category pill
                    Text(article.type.rawValue.capitalized)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    // Status indicators
                    HStack(spacing: 4) {
                        if isRead {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                                .padding(4)
                                .background(.ultraThinMaterial)
                            
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(article.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedDate(from: article.dateAdded))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
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
    
    private func focusAreaIcon(for focusArea: FocusArea) -> String {
        switch focusArea {
        case .eye:
            return "eye"
        case .back:
            return "figure.walk"
        case .wrist:
            return "hand.raised"
        }
    }
    
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

struct ModernLatestArticleSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray6))
                .frame(height: 150)
                .cornerRadius(12, corners: [.topLeft, .topRight])
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 20)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                    .cornerRadius(4)
                    .frame(width: 120)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                    .cornerRadius(4)
                    .frame(width: 80)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .frame(width: 230)
        .redacted(reason: .placeholder)
    }
}

// Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
