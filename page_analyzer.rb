require_relative 'openai_gpt4'

class PageAnalyzer
  def initialize(page_content)
    @page_content = page_content
  end

  def analyze
      qq = <<-QUERY
      Here is an HTML page. I would like you to examine its content and generate a list of HTML elements such as link, button, input, div, li, etc. Each pair in the list should consist of a CSS selector that identifies the HTML element as the first item, followed by a brief one-sentence summary describing the function or purpose of the element as the second item. An example pair might look like this: [".div a", "Login link"]. If "id" is present use it as the selector. Please refrain from adding any additional text or commentary beyond this structure.
      QUERY

    OpenAIGPT4.new(qq).query(prompt: @page_content)
  end
end
