require "nethttputils"
require "json"
require "logger"
require "base64"

module GPT

  require "fileutils"
  ::FileUtils.mkdir_p "logs_gpt"
  require "logger"
  @logger = ::Logger.new "logs_gpt/txt", "weekly", progname: name, datetime_format: "%y%m%d %H%M%S", formatter: ->(severity, datetime, progname, msg){
    fail unless msg.is_a? ::String
    "#{datetime} #{severity.to_s[0]} #{::Base64.strict_encode64 msg}\n"
  }

  def self.completions endpoint, secret, model, query, system_message, context = nil, max_tokens: 150, temperature: 0
    form = {
      "model" => model,
      "messages" => [
        {"role" => "system", "content" => system_message},
        *context,
        {"role" => "user", "content" => query},
      ],
      "max_tokens" => max_tokens,
      "temperature" => temperature,
    }
    begin
      ::NetHTTPUtils.request_data "https://#{endpoint}/chat/completions", :POST, :json,
        max_start_http_retry_delay: 300,
        header: {"Authorization" => "Bearer #{secret}"},
        form: form
    rescue ::NetHTTPUtils::Error
      fail unless 502 == $!.code || 400 == $!.code || [
        '{"detail":"Forbidden: flagged moderation category: sexual"}',
        '{"error":{"message":"Forbidden: flagged moderation categories: self-harm, self-harm/intent, self-harm/instructions"}}',
        '{"error":{"message":"Forbidden: flagged moderation category: harassment"}}',
        '{"error":{"message":"Oops, no sources were found for this model!"}}',
      ].include?($!.body)
      ::STDERR.puts $!
    end.then(&::JSON.method(:load)).tap do |json|
      @logger.debug ::JSON.dump [form, json]
      ::Nakischema.validate json, { hash_req: {
        "choices" => [[
          { hash_req: {
            "finish_reason" => ["stop", "length", nil],
            "index" => 0..0,
            "message" => { hash: {"content" => ::String, "role" => "assistant"} },
          } },
        ]],
        "created" => ::Integer,
        "id" => ::String,
        "model" => ::String,
        "object" => "chat.completion",
      }, hash_opt: {
        "usage" => { hash: {  # zuki may return nil, naga won't
          "completion_tokens" => [::Integer, nil],
          "prompt_tokens" => [::Integer, nil],
          "total_tokens" => [::Integer, nil],
        } },
      } }
    end["choices"][0]["message"]["content"]
  end

end
