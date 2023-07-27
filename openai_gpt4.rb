require_relative 'gpt_chat_bot'

class OpenAIGPT4

  attr_accessor :chatbot

  def initialize(initial_message = nil)
    @system_message = [{ role: "system", content: initial_message }]
    @chatbot = GptChatBot.new(messages: @system_message)
  end

  def query(prompt:, extra_context: nil)
    prompt = "#{extra_context}\n\n#{prompt}" if extra_context
    chatbot.messages << { role: "user", content: prompt }
    model = extra_context.nil? ? "gpt-3.5-turbo-16k" : "gpt-4"
    chatbot.gpt(temperature: 0.7, model: model)
    response, usage = chatbot.gpt(temperature: 0.7, model: model)
    chatbot.messages << { role: "assistant", content: response } if response
    response
  end
end
