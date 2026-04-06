/// Centralized API Configuration for the Aquaculture App.
/// 
/// Set to the production Render URL for real-world devices.
// For real devices, replace 'localhost' with your computer's local IP address (e.g., 192.168.1.15)
const String BASE_URL = "https://aquaculture-backend.onrender.com/api/v1";

/// Default timeout for API requests (60 seconds for Render cold starts).
const Duration API_TIMEOUT = Duration(seconds: 60);
