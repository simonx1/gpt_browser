require_relative 'openai_gpt4'

class PageAnalyzer
  def initialize(page_content)
    @page_content = page_content
  end

  def analyze
      qq = <<~QUERY
      Examine the HTML code provided and list the HTML elements used. Include the tag name, CSS selectors (using the "id" attribute if available), and a brief summary of the purpose of each element. The information should be presented in pairs, like this: button#gksS1d: "A sign in form submit button". Do not include any additional text or commentary.
      QUERY

    OpenAIGPT4.new(qq).query(prompt: @page_content)
  end
end
