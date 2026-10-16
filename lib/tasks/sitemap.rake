# rubocop:disable Metrics/BlockLength
namespace :sitemap do
  desc 'Generate sitemap and optionally submit to Google Search Console'
  task generate: :environment do
    puts '🗺️  Generating sitemap...'

    begin
      # Generate the sitemap. config/sitemap.rb calls create with a block,
      # which is what version 7 finalizes. create with no block does not.
      SitemapGenerator::Sitemap.verbose = true
      SitemapGenerator::Interpreter.run

      puts '✅ Sitemap generated successfully!'

      # Submit to Google Search Console if credentials are available
      if ENV['GOOGLE_SEARCH_CONSOLE_SITE_URL'] && ENV['GOOGLE_SEARCH_CONSOLE_CREDENTIALS']
        submit_to_google
      else
        puts '⚠️  Google Search Console credentials not configured. Skipping submission.'
        puts '   Set GOOGLE_SEARCH_CONSOLE_SITE_URL and GOOGLE_SEARCH_CONSOLE_CREDENTIALS to enable.'
      end
    rescue StandardError => e
      puts "❌ Error generating sitemap: #{e.message}"
      exit(1)
    end
  end

  desc 'Submit sitemap to Google Search Console'
  task submit_to_google: :environment do
    submit_to_google
  end

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def submit_to_google
    require 'net/http'
    require 'json'

    puts '📤 Submitting sitemap to Google Search Console...'

    site_url = ENV.fetch('GOOGLE_SEARCH_CONSOLE_SITE_URL', nil)
    credentials_path = ENV.fetch('GOOGLE_SEARCH_CONSOLE_CREDENTIALS', nil)

    unless File.exist?(credentials_path)
      puts "❌ Google credentials file not found: #{credentials_path}"
      return
    end

    begin
      # Load Google API credentials
      credentials = JSON.parse(File.read(credentials_path))

      # Get access token (you'll need to implement OAuth2 flow)
      access_token = get_google_access_token(credentials)

      # Submit sitemap
      sitemap_url = "#{site_url}/sitemap.xml"
      submit_url = "https://searchconsole.googleapis.com/v1/sites/#{CGI.escape(site_url)}/sitemaps/#{CGI.escape(sitemap_url)}"

      uri = URI(submit_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Put.new(uri)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'

      response = http.request(request)

      if response.code == '200'
        puts '✅ Sitemap submitted to Google Search Console successfully!'
      else
        puts "⚠️  Failed to submit sitemap: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      puts "❌ Error submitting to Google: #{e.message}"
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def get_google_access_token(_credentials)
    # This is a simplified version. In production, you'd want to implement
    # proper OAuth2 flow with refresh tokens
    puts '⚠️  Google OAuth2 implementation needed for production use'
    puts '   For now, you can manually submit sitemaps via Google Search Console'
    nil
  end
end
# rubocop:enable Metrics/BlockLength
