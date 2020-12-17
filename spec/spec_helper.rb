require 'puppeteer'
require 'pages'

module SinatraRouting
  def prepare_page(&block)
    require 'net/http'
    require 'sinatra/base'
    require 'timeout'

    sinatra_app = Sinatra.new do
      get('/_ping') { '_pong' }
      get('/page.html', &block)
    end

    around do |example|
      Thread.new { sinatra_app.run!(port: 4567) }
      Timeout.timeout(3) do
        loop do
          Net::HTTP.get(URI("http://127.0.0.1:4567/_ping"))
          break
        rescue Errno::ECONNREFUSED
          sleep 0.1
        end
      end
      begin
        page.goto('http://127.0.0.1:4567/page.html')
        example.run
      ensure
        sinatra_app.quit!
      end
    end
  end
end

RSpec::Core::ExampleGroup.extend(SinatraRouting)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  launch_options = {
    executable_path: ENV['PUPPETEER_EXECUTABLE_PATH'],
  }.compact
  unless ENV['CI']
    launch_options[:headless] = false
  end

  config.around(:each) do |example|
    Puppeteer.launch(**launch_options) do |browser|
      context = browser.create_incognito_browser_context
      @puppeteer_page = context.new_page
      begin
        example.run
      ensure
        @puppeteer_page.close
      end
    end
  end

  # Every unit test case should spend less than 15sec.
  config.around(:each, :unit) do |example|
    Timeout.timeout(15) { example.run }
  end

  config.define_derived_metadata(file_path: %r(/spec/unit_test/)) do |metadata|
    metadata[:type] = :unit
  end

  module PuppeteerMethods
    def page
      @puppeteer_page or raise NoMethodError.new('undefined method "page"')
    end
  end
  config.include PuppeteerMethods
end
