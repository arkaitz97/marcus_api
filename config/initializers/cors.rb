Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      # Specify the origins allowed to make requests to your API.
      # For development, list your frontend development server's origin.
      # IMPORTANT: For production, replace these with your actual frontend domain(s).
      # Using '*' allows any origin, which is insecure for production but can be
      # useful for quick local testing if you're unsure of the port.
      origins 'localhost:5173', '127.0.0.1:5173'
      # origins '*' # Use with caution, especially not in production!
  
      resource '*', # Allow all resources (API routes)
        headers: :any, # Allow any headers in the request
        methods: [:get, :post, :put, :patch, :delete, :options, :head], # Allow standard HTTP methods
        # expose: ['access-token', 'expiry', 'token-type', 'uid', 'client'], # Optional: Expose specific headers to the frontend
        credentials: false # Set to true if you need to send cookies or use HTTP Basic Auth cross-origin
    end
  end