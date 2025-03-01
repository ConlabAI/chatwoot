class Integrations::Openai::ProcessorService
  # 3.5 support 4,096 tokens
  # 1 token is approx 4 characters
  # 4,096 * 4 = 16,384 characters, sticking to 15,000 to be safe
  TOKEN_LIMIT = 15_000
  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion].freeze

  attr_reader :hook, :event, :api_url, :gpt_model

  def initialize(hook:, event:)
    @hook = hook
    @event = event
    set_api_url_and_gpt_model
  end

  def perform
    event_name = event['name']
    return nil unless valid_event_name?(event_name)

    send("#{event_name}_message")
  end

  private

  def valid_event_name?(event_name)
    ALLOWED_EVENT_NAMES.include?(event_name)
  end

  def rephrase_body
    {
      model: gpt_model,
      messages: [
        { role: 'system',
          content: "You are a helpful support agent. Please rephrase the following response to a more #{event['data']['tone']} tone. " \
                   "Reply in the user's language." },
        { role: 'user', content: event['data']['content'] }
      ]
    }.to_json
  end

  def conversation_messages(in_array_format: false)
    conversation = find_conversation
    messages = init_messages_body(in_array_format)

    add_messages_until_token_limit(conversation, messages, in_array_format)
  end

  def find_conversation
    hook.account.conversations.find_by(display_id: event['data']['conversation_display_id'])
  end

  def add_messages_until_token_limit(conversation, messages, in_array_format)
    character_count = 0
    conversation.messages.chat.reorder('id desc').each do |message|
      character_count, message_added = add_message_if_within_limit(character_count, message, messages, in_array_format)
      break unless message_added
    end
    messages
  end

  def add_message_if_within_limit(character_count, message, messages, in_array_format)
    if valid_message?(message, character_count)
      add_message_to_list(message, messages, in_array_format)
      character_count += message.content.length
      [character_count, true]
    else
      [character_count, false]
    end
  end

  def valid_message?(message, character_count)
    message.content.present? && character_count + message.content.length <= TOKEN_LIMIT
  end

  def add_message_to_list(message, messages, in_array_format)
    formatted_message = format_message(message, in_array_format)
    messages.prepend(formatted_message)
  end

  def init_messages_body(in_array_format)
    in_array_format ? [] : ''
  end

  def format_message(message, in_array_format)
    in_array_format ? format_message_in_array(message) : format_message_in_string(message)
  end

  def format_message_in_array(message)
    { role: (message.incoming? ? 'user' : 'assistant'), content: message.content }
  end

  def format_message_in_string(message)
    sender_type = message.incoming? ? 'Customer' : 'Agent'
    "#{sender_type} #{message.sender&.name} : #{message.content}\n"
  end

  def summarize_body
    {
      model: gpt_model,
      messages: [
        { role: 'system',
          content: 'Please summarize the key points from the following conversation between support agents and ' \
                   'customer as bullet points for the next support agent looking into the conversation. Reply in the user\'s language.' },
        { role: 'user', content: conversation_messages }
      ]
    }.to_json
  end

  def reply_suggestion_body
    {
      model: gpt_model,
      messages: [
        # Conlab note: Do not include the system message, as it will be added by the Assistant
        # { role: 'system',
        #   content: 'Please suggest a reply to the following conversation between support agents and customer. Reply in the user\'s language.' }
      ].concat(conversation_messages(in_array_format: true)),
      # Conlab: Pass conversation id as user to match traces with conversations
      user: event['data']['conversation_display_id'].to_s
    }.to_json
  end

  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  def summarize_message
    make_api_call(summarize_body)
  end

  def rephrase_message
    make_api_call(rephrase_body)
  end

  def make_api_call(body)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{hook.settings['api_key']}"
    }

    response = HTTParty.post(api_url, headers: headers, body: body)
    JSON.parse(response.body)['choices'].first['message']['content']
  end

  def set_api_url_and_gpt_model
    @api_url = hook.settings['api_url'].presence || 'https://api.openai.com/v1/chat/completions'
    @gpt_model = hook.settings['model_name'].presence || 'gpt-3.5-turbo'
  end
end
