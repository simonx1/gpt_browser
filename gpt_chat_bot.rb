#!/usr/bin/env ruby
require 'dotenv/load'
require 'ruby/openai'
require 'logger'

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_API_KEY')
  config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
  config.request_timeout = 240
end

COMMANDS_HISTORY_FILE = ".history.txt"

class GptChatBot
  attr_accessor :messages

  def initialize(messages:, client: OpenAI::Client.new, logger: Logger.new('logfile.log', level: :info))
    @client = client
    @logger = logger
    @messages = messages
  end

  def gpt(temperature: 0.1, model: "gpt-4")
    t = Time.now

    parameters = {
      model: model,
      messages: messages,
      temperature: temperature.to_f,
    }

    response = execute_with_log(api_method: "chat", params: parameters) do |params|
      client.chat(parameters: params)
    end

    t = Time.now - t
    puts "\nResponded in #{t} sek.\n\n"

    last_response = response.dig("choices", 0, "message", "content")
    usage = response["usage"]

    File.open(COMMANDS_HISTORY_FILE, "a+") { |file| file.puts "#{Time.now}##ChatGPT###{messages}###{last_response}" }

    [last_response, usage]
  end

  def gpt_stream(temperature: 0.7, model: "gpt-4", stream: [])
    t = Time.now

    parameters = {
      model: model,
      messages: messages,
      temperature: temperature.to_f,
      stream: proc do |chunk, _bytesize|
        output = chunk.dig("choices", 0, "delta", "content")
        File.open(COMMANDS_HISTORY_FILE, "a+") { |file| file.puts "#{Time.now}##ChatGPTSteamPart###{output}" }
        stream << output
      end
    }

    File.open(COMMANDS_HISTORY_FILE, "a+") { |file| file.puts "#{Time.now}##ChatGPTStream###{messages}" }

    response = client.chat(parameters: parameters)

    t = Time.now - t
    puts "\nResponded in #{t} sek.\n\n"

    response
  end

  private

  attr_reader :client, :logger

  def execute_with_log(api_method:, params:)
    logger.info "API call `#{api_method}` with: #{params}"
    response = yield(params)
    logger.info "API call `completions` response: #{response}"
    response
  end
end
