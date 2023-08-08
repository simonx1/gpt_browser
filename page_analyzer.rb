require_relative 'openai_gpt4'

class PageAnalyzer
  def initialize(page_content)
    @page_content = page_content
  end

  def analyze
      qq = <<~QUERY
      Please analyze the content of this HTML page and create a comprehensive list of HTML elements, including their tag name corresponding CSS selectors and a concise one-sentence summary describing the purpose of each element based on the type of element and text inside it. Use the "id" attribute as the selector if it is present. An example pair might look like this: button#gksS1d: "A sign in form submit button". Avoid including any extra text or commentary beyond this format.
      QUERY

    OpenAIGPT4.new(qq).query(prompt: @page_content)
  end
end
