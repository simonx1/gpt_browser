require 'selenium-webdriver'
require 'nokogiri'
require_relative 'page_analyzer'
require_relative 'action_executor'
require_relative 'openai_gpt4'
require 'pry'

class ChatBot

  attr_reader :driver

  def initialize
    @driver = Selenium::WebDriver.for :chrome
    @openai_gpt4 = OpenAIGPT4.new("You are a Ruby developer. Please write Ruby code that uses Selenium gem do \ 
execute given command based on the HTML page content. Focus only on the action from prompt, do not generate code for all elements. \
Do not generate selenium connection boilerplate code. \
No other text, just Ruby code. @driver is a Selenium::WebDriver instance.")
  end

  def navigate_to(url)
    driver.navigate.to url
  end

  def sanitize_page(strict: true)
    # Get the page source
    source = driver.page_source

    # Use Nokogiri to parse the source
    html_doc = Nokogiri::HTML(source)

    html_doc  = remove_redundant_elements(html_doc)
    html_doc  = remove_non_actionable_elements(html_doc) if strict == true

    # Get the HTML content without script and style tags
    puts "\n\n\n #{html_doc.to_html}\n\n"
    html_doc.to_html
  end

  def remove_redundant_elements(html_doc)
    # Remove all script and style tags
    xpath = '//script | //style | //svg | //head | //iframe | //link'
    html_doc.xpath(xpath).remove
    html_doc
  end

  def remove_non_actionable_elements(html_doc)
    # Define the XPath for actionable elements.
    xpath = '//html | //body | //a | //input | //button | //*[@tabindex or @role or @onclick or @onmousedown or @onmouseup or @onkeydown or @onkeyup or @onkeypress]'
  
    # Get actionable elements.
    actionable_elements = html_doc.xpath(xpath)
  
    # Get all elements and convert to array.
    all_elements = html_doc.xpath('//*').to_a
  
    # Calculate non-actionable elements by subtracting actionable elements from all elements.
    non_actionable_elements = all_elements - actionable_elements
  
    # Remove non-actionable elements from the HTML document only if they don't contain any actionable elements.
    non_actionable_elements.each do |element|
      element.remove if (element.xpath('.//*') & actionable_elements).empty?
    end
  
    html_doc
  end

  def analyze_page
    page = PageAnalyzer.new(sanitize_page).analyze
    page = driver.find_element(tag_name: 'body').text if page.nil?
    puts "Page analysis or text content:\n\n #{page}\n\n"
    page
  end

  def execute_action(action)
    page_content = driver.page_source
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
      puts "Predefined commands: analyze page, manual mode, binding.pry, exit.\nPlease enter a command:"
      command = gets.chomp
      next if command.empty?
      if command.downcase == 'analyze page'
        page = analyze_page
        next
      elsif command.downcase == 'manual mode'
        puts 'Please enter a ruby code:'
        command = gets.chomp
        begin
          eval(command)
        rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::ElementNotInteractableError => e
          puts "Element not found: #{e}"
        end
        next
      elsif command.downcase == 'binding.pry'
        binding.pry
        next
      elsif command.downcase == 'exit'
        driver.quit
        exit-program
      end

      action = @openai_gpt4.query(prompt: command, extra_context: page)
      puts "Generated code:\n*******\n#{action}\n*******"
      puts 'Do you want to execute this code? (yes/no)'
      answer = gets.chomp
      if answer.downcase == 'yes'
        begin
          eval(action)
        rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::ElementNotInteractableError => e
          puts "Element not found: #{e}"
        end
      end
    end
  end
end
