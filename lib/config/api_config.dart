/// Centralized API Configuration for the Aquaculture App.
/// 
/// Set to the production Render URL for real-world devices.
// For real devices, replace 'localhost' with your computer's local IP address (e.g., 192.168.1.15)
const String BASE_URL = "http://localhost:8000/api/v1";

/// Default timeout for API requests (60 seconds for Render cold starts).
const Duration API_TIMEOUT = Duration(seconds: 60);
