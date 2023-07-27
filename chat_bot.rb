require 'selenium-webdriver'
require 'nokogiri'
require_relative 'page_analyzer'
require_relative 'action_executor'
require_relative 'openai_gpt4'
require 'pry'

class ChatBot
  def initialize
    @driver = Selenium::WebDriver.for :chrome
    @openai_gpt4 = OpenAIGPT4.new("You are a Ruby developer. Please write Ruby code that uses Selenium gem do \ 
execute given command based on the HTML page content. Focus only on the action from prompt, do not generate code for all elements. \
Do not generate selenium connection boilerplate code. \
No other text, just Ruby code. @driver is a Selenium::WebDriver instance.")
  end

  def navigate_to(url)
    @driver.navigate.to url
  end

  def sanitize_page
    # Get the page source
    source = @driver.page_source

    # Use Nokogiri to parse the source
    doc = Nokogiri::HTML(source)

    # Remove all script and style tags
    doc.xpath('//script').remove
    doc.xpath('//style').remove
    doc.xpath('//svg').remove

    # Get the HTML content without script and style tags
    puts "\n\n\n #{doc.to_html}\n\n"
    doc.to_html
  end

  def analyze_page
    PageAnalyzer.new(sanitize_page).analyze
    page = @driver.find_element(tag_name: 'body').text if page.nil?
    puts "Page analysis or text content:\n\n #{page}\n\n"
    page
  end

  def execute_action(action)
    page_content = @driver.page_source
    ActionExecutor.new(page_content, action).execute
  end

  def run
    puts 'Please enter the website URL:'
    url = gets.chomp
    url = "https://#{url}" unless url.start_with?('http://', 'https://')
    begin
      navigate_to(url.downcase)
    rescue Selenium::WebDriver::Error::InvalidArgumentError => e
      exit("Invalid URL: #{url}")
    end
    
    page = analyze_page

    loop do
      puts 'Please enter a command:'
      command = gets.chomp
      next if command.empty?
      if command == 'analyze page'
        page = analyze_page
        next
      end

      action = @openai_gpt4.query(prompt: command.downcase, extra_context: page)
      puts "Generated code:\n*******\n#{action}\n*******"
      puts 'Do you want to execute this code? (yes/no)'
      answer = gets.chomp
      if answer.downcase == 'yes'
        begin
          eval(action)
        rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::ElementNotInteractableError => e
          puts "Element not found: #{e}"
        end
      elsif answer.downcase == 'exit'
        exit
      end
    end
  end
end
