require "telegram/bot"
require_relative "board"

class XOXBot
  TOKEN = ENV["TELEGRAM_BOT_TOKEN"].freeze
  MESSAGE_TRY_MORE = "Try one more time or \ntype /stop for exit".freeze
  MESSAGE_WHO_START = "Who will start?\nYou or Bot?".freeze
  MESSAGE_MAKE_CHOISE = "Make your choice:".freeze

  def initialize
    @games = {}      # Hash for users boards
  end

  def run
    bot.listen do |message|
      process_message(message)
    rescue => e
      puts e.message
    end
  end
    
  private

  def bot
    @bot ||= Telegram::Bot::Client.new(TOKEN)
  end

  def process_message(message)
    case message
    when Telegram::Bot::Types::CallbackQuery
      handle_callback_query(message)
    when Telegram::Bot::Types::Message
      handle_message(message)
    end
  end

  def handle_callback_query(message)
    case message.data
    when "user"                                 # user's step first
      update_game_board(message)
    when "bot"                                  # bot's step first
      @games[message.from.id].game_cycle
      update_game_board(message)
    when "1".."9"                               # user made chose of cell for the next step
      result = @games[message.from.id].game_cycle(message.data.to_i)
      update_game_board(message)
      unless result.to_s.empty? 
        @games[message.from.id] = Board.new
        send_message(message.message.chat.id, result)
        send_message(message.message.chat.id, MESSAGE_TRY_MORE)
        send_initial_markup(message.message)
      end  
    when "disable"
      # Do nothing, the button is disable
    end
  end

  def handle_message(message)
    case message.text
    when "/start"                               # command to stop finish with box
      puts message.from.first_name + " start game"
      @games[message.from.id] = Board.new
      send_message(message.chat.id, "Hello, #{message.from.first_name}!")
      send_initial_markup(message)
    when "/stop"                                # command to stop work with box
      send_message(message.chat.id, "Good bye, #{message.from.first_name}!")
      @games.delete(message.from.id)
    end
  end
  
  def send_message(chat_id, text, reply_markup = nil)
    bot.api.send_message(chat_id: chat_id, text: text, reply_markup: reply_markup)
  end

  def send_initial_markup(message)
    answers = [
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "I", callback_data: "user")],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "Bot", callback_data: "bot")]
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: answers)

    bot.api.send_message(chat_id: message.chat.id, text: MESSAGE_WHO_START, reply_markup: markup)
  end

  def update_game_board(message)
    new_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: generate_keyboard_markup(message))
    
    bot.api.edit_message_text(
      chat_id: message.message.chat.id,
      message_id: message.message.message_id,
      text: MESSAGE_MAKE_CHOISE,
      reply_markup: new_markup
    )
  end
  
  def generate_keyboard_markup(message)
   @games[message.from.id].get_board_state.each_with_index.map do |row, i|
      row.map.with_index do |cell, j|
        create_cell_button(cell, i, j)
      end
    end
  end
  
  def create_cell_button(cell, row_index, col_index)
    text = cell.empty? ? " " : cell 
    callback_param = cell.empty? ? "#{row_index * 3 + col_index + 1}" : "disable"
    Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: callback_param)
  end
end
