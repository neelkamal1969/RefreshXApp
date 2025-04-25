import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            
            UserProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
            
            ExerciseLibraryView()
                .tabItem { Label("Exercises", systemImage: "figure.walk") }
            
            ArticlesView()
                .tabItem { Label("Articles", systemImage: "book") }
            
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .environmentObject(authViewModel)
        .onAppear {
                        // correct the transparency bug for Tab bars
                        let tabBarAppearance = UITabBarAppearance()
                        tabBarAppearance.configureWithOpaqueBackground()
                        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                        // correct the transparency bug for Navigation bars
                        let navigationBarAppearance = UINavigationBarAppearance()
                        navigationBarAppearance.configureWithOpaqueBackground()
                        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
                    }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}
