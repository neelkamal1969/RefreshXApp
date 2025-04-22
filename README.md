<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 800px; margin: 0 auto; color: #333; line-height: 1.6;">
  <div style="text-align: center; margin-bottom: 30px;">
    <h1 style="color: #2c3e50; font-size: 2.5em; margin-bottom: 10px;">RefreshX</h1>
    <h2 style="color: #7f8c8d; font-weight: 400; margin-top: 0;">Wellness Breaks for Focused Minds</h2>
    <p style="font-size: 1.1em;">A comprehensive wellness companion for desk workers</p>
    <img src="https://media-hosting.imagekit.io/bf56fe771bca4d40/appImage.jpg?Expires=1839969264&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=cEi8lv3X4ixsDiBaqUJK16Z3XClILJt9jVleiVHoNmOnj8BADf0xhAIxeZ2CMics3LtC3KziWxaq10u5prJc4qj3Pbh1A4P0wdhOspThU0ohJut2M8e-2T3kBmiU1GS8SIVlCtFajWDBE63C6hpJmmpEMCAYs3-FODYIBMY5XdIRd8ptLviwxRFzYrqcSw5RUWK-FUj4dGIhzVrSNqH48h7XKbVK~j5J5n-zJmU-g5~jMyauHrZGkqMzqowl3QRcwJgCzHPF3L5Ts1tsBljOFwKmkFoDfrLVHMqvUZEs9CtepgWVvyQqSs-ozi8VG5eCcKQ1fFDDcrLV3qMPVaGu~A__" alt="RefreshX App Screenshot" style="max-width: 100%; border-radius: 8px; margin: 20px 0; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
  </div>

  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">About RefreshX</h2>
    <p>RefreshX is an innovative wellness companion designed to help desk workers prevent strain and fatigue through regular, mindful breaks. The app addresses common health issues associated with extended computer use—eye strain, back pain, and wrist discomfort—through a thoughtfully designed break scheduling system integrated with guided exercises.</p>
    <p>With RefreshX, you can set your work schedule, and the app will automatically plan balanced breaks throughout your day. Each break features guided exercises specifically designed for eye relief, back stretching, or wrist care. You'll receive notifications 5 minutes before each scheduled break, helping you transition smoothly from work to wellness moments.</p>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Key Features</h2>
    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px;">
      <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px;">
        <h3 style="margin-top: 0; color: #2980b9;">🕒 Smart Break Scheduling</h3>
        <ul style="padding-left: 20px;">
          <li>Set your work hours and days</li>
          <li>Automatic distribution of breaks throughout your workday</li>
          <li>Customizable break frequency and duration</li>
        </ul>
      </div>
      <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px;">
        <h3 style="margin-top: 0; color: #2980b9;">💪 Guided Exercises</h3>
        <ul style="padding-left: 20px;">
          <li>Specialized routines targeting eyes, back, and wrists</li>
          <li>Step-by-step instructions for each exercise</li>
          <li>Categorized by body focus area for targeted relief</li>
        </ul>
      </div>
      <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px;">
        <h3 style="margin-top: 0; color: #2980b9;">📚 Educational Content</h3>
        <ul style="padding-left: 20px;">
          <li>Curated articles on workplace wellness</li>
          <li>Information organized by focus area</li>
          <li>Save favorites for quick access</li>
        </ul>
      </div>
      <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px;">
        <h3 style="margin-top: 0; color: #2980b9;">📊 Progress Tracking</h3>
        <ul style="padding-left: 20px;">
          <li>Daily activity calendar</li>
          <li>Streak counting for consistent break habits</li>
          <li>Calorie calculations based on MET scores</li>
          <li>Detailed statistics and wellness history</li>
        </ul>
      </div>
      <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px;">
        <h3 style="margin-top: 0; color: #2980b9;">🔐 Secure Authentication</h3>
        <ul style="padding-left: 20px;">
          <li>Simple email-based OTP system</li>
          <li>No passwords to remember</li>
          <li>Secure data handling</li>
        </ul>
      </div>
    </div>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Technical Architecture</h2>
    <p>RefreshX is built with a modern tech stack following the MVVM (Model-View-ViewModel) architecture:</p>
    
    <h3 style="color: #16a085;">Frontend</h3>
    <ul style="padding-left: 20px;">
      <li><strong>SwiftUI:</strong> Modern declarative UI framework for all interface components</li>
      <li><strong>Combine:</strong> Reactive programming for state management</li>
    </ul>
    
    <h3 style="color: #16a085;">Backend</h3>
    <ul style="padding-left: 20px;">
      <li><strong>Supabase:</strong> Backend-as-a-Service platform providing:
        <ul>
          <li>Authentication</li>
          <li>PostgreSQL database</li>
          <li>Storage for content</li>
          <li>Row-level security</li>
        </ul>
      </li>
    </ul>
    
    <h3 style="color: #16a085;">Data Management</h3>
    <ul style="padding-left: 20px;">
      <li><strong>Models:</strong> Swift structures reflecting database tables</li>
      <li><strong>ViewModels:</strong> ObservableObjects managing business logic and state</li>
      <li><strong>Views:</strong> SwiftUI components for user interface</li>
    </ul>
    
    <h3 style="color: #16a085;">Key Components</h3>
    <ul style="padding-left: 20px;">
      <li><strong>NotificationManager:</strong> Handles local notification scheduling</li>
      <li><strong>AuthViewModel:</strong> Manages authentication state and user data</li>
      <li><strong>HomeViewModel:</strong> Controls break timing and exercise flow</li>
      <li><strong>ProgressViewModel:</strong> Tracks and calculates statistics</li>
    </ul>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Getting Started</h2>
    
    <h3 style="color: #16a085;">Requirements</h3>
    <ul style="padding-left: 20px;">
      <li>iOS 16.0 or later</li>
      <li>Xcode 14.0 or later</li>
      <li>Swift 5.7 or later</li>
      <li>Supabase account (for backend services)</li>
    </ul>
    
    <h3 style="color: #16a085;">Installation</h3>
    <ol style="padding-left: 20px;">
      <li>Clone the repository:
        <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 5px; overflow-x: auto;"><code>git clone https://github.com/neelkamal1969/RefreshXApp.git</code></pre>
      </li>
      <li>Open the project in Xcode:
        <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 5px; overflow-x: auto;"><code>open RefreshX.xcodeproj</code></pre>
      </li>
      <li>Install dependencies using Swift Package Manager:
        <p>Xcode should automatically resolve dependencies.<br>
        If not, go to File > Swift Packages > Resolve Package Versions.</p>
      </li>
      <li>Configure Supabase credentials:
        <p>Open <code>SupabaseClient.swift</code>.<br>
        Update with your Supabase URL and API key.</p>
      </li>
      <li>Build and run the application:
        <p>Select an iOS simulator or device.<br>
        Press Command+R or click the Run button.</p>
      </li>
    </ol>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Usage Guide</h2>
    
    <h3 style="color: #16a085;">First-time Setup</h3>
    <ol style="padding-left: 20px;">
      <li>Launch the app and enter your email address.</li>
      <li>Check your email for the verification code (OTP).</li>
      <li>Enter the code to complete authentication.</li>
      <li>Set up your profile with optional details like height and weight.</li>
      <li>Configure your work schedule and break preferences.</li>
    </ol>
    
    <h3 style="color: #16a085;">Daily Workflow</h3>
    <ul style="padding-left: 20px;">
      <li>The app automatically schedules breaks based on your settings.</li>
      <li>Receive notifications 5 minutes before scheduled breaks.</li>
      <li>Follow guided exercises during break sessions.</li>
      <li>Mark exercises as complete to track progress.</li>
      <li>Review your daily and weekly statistics.</li>
    </ul>
    
    <h3 style="color: #16a085;">Customizing Your Experience</h3>
    <ul style="padding-left: 20px;">
      <li><strong>Profile Screen:</strong> Update work hours, break frequency, and personal details.</li>
      <li><strong>Exercise Library:</strong> Add or remove exercises from your routine.</li>
      <li><strong>Articles:</strong> Save favorites for quick reference.</li>
      <li><strong>Home Screen:</strong> Start manual breaks anytime you need.</li>
    </ul>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Privacy and Data Handling</h2>
    <p>RefreshX respects your privacy and only collects essential information:</p>
    <ul style="padding-left: 20px;">
      <li>Email address (for authentication)</li>
      <li>Name, height, and weight (for personalized calculations)</li>
      <li>Break and exercise preferences</li>
      <li>Activity history</li>
    </ul>
    <p>All data is stored securely on Supabase servers with appropriate encryption and is never shared with third parties. For more details, see our <a href="#" style="color: #3498db; text-decoration: none;">Privacy Policy</a>.</p>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Support and Feedback</h2>
    <p>For support, questions, or feedback, please contact:</p>
    <ul style="padding-left: 20px;">
      <li>Email: <a href="mailto:heeyyyprince@gmail.com" style="color: #3498db; text-decoration: none;">heeyyyprince@gmail.com</a></li>
      <li>Website: <a href="#" style="color: #3498db; text-decoration: none;">Support Website</a></li>
    </ul>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Development Team</h2>
    <ul style="padding-left: 20px;">
      <li><strong>Prince Kumar:</strong> Project Lead & UX/UI Lead</li>
      <li><strong>Rishabh Singh:</strong> Backend Development Lead</li>
      <li><strong>Kinshuk:</strong> UI/UX Support & Documentation</li>
      <li><strong>Neelkamal:</strong> Testing, R&D & Support Lead</li>
    </ul>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Institutional Support</h2>
    <p>We extend our gratitude to <a href="#" style="color: #3498db; text-decoration: none;">Chitkara University, Rajpura, Punjab</a>, for providing the resources, mentorship, and academic environment that made RefreshX possible.</p>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">License</h2>
    <p>This project is licensed under the MIT License - see the <a href="#" style="color: #3498db; text-decoration: none;">LICENSE</a> file for details.</p>
  </div>

  <div style="margin-bottom: 30px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px;">Acknowledgments</h2>
    <ul style="padding-left: 20px;">
      <li>Swift Developer Documentation</li>
      <li>Apple Developer Tutorials</li>
      <li>Supabase Documentation</li>
      <li>Stack Overflow Community</li>
    </ul>
  </div>

  <div style="text-align: center; padding: 20px; background-color: #f8f9fa; border-radius: 8px;">
    <h2 style="color: #2c3e50; margin-top: 0;">RefreshX</h2>
    <p style="font-size: 1.1em; margin-bottom: 0;">Your wellness companion for a healthier workday</p>
  </div>
</div>





RefreshX
A comprehensive wellness companion for desk workers.
View the full documentation here: RefreshX Documentation
For more details, check out the docs/index.html file in this repository.
