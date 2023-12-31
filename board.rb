class Board
  MESSAGE_WINER = "Congratulation! You are winner".freeze
  MESSAGE_LOSER = "Sorry! Bot wins".freeze
  MESSAGE_DRAW = "Game over! Draw...".freeze
  USER_MARK = "❌".freeze
  BOT_MARK  = "⭕".freeze
  BOARD_RATE = [3, 2, 3, 2, 4, 2, 3, 2, 3].freeze
  RELATED_CELLS = {
    0 => [[1, 2], [3, 6], [4, 8]],
    1 => [[0, 2], [4, 7]],
    2 => [[0, 1], [4, 6], [5, 8]],
    3 => [[0, 6], [4, 5]],
    4 => [[0, 8], [1, 7], [2, 6], [3, 5]],
    5 => [[2, 8], [3, 4]],
    6 => [[0, 3], [2, 4], [7, 8]],
    7 => [[1, 4], [6, 8]],
    8 => [[0, 4], [2, 5], [6, 7]],
  }.freeze

  def initialize
    @step_counter = 0
    @board        = (1..9).to_a
    @boardRate    = BOARD_RATE.dup
    @winner       = ""
  end
  
  def get_board_state
    @board.map { |item| item.is_a?(Numeric) ? "" : item }.each_slice(3).to_a
  end

  def game_cycle(cell_number = -1)  
    if cell_number != -1                  # if bot starts skip user step 
      result = user_step(cell_number)
      return result unless result.to_s.empty?
    end  
    bot_step
  end

  private
  
  def bot_step
    cell_number = @boardRate.each_with_index.max[1]
    next_step(cell_number , BOT_MARK)
  end 

  def user_step(cell_number)
    next_step(cell_number - 1, USER_MARK)
  end  

  def next_step(cell_number, mark)
    return if @boardRate[cell_number] == 0
    @step_counter += 1

    @board[cell_number] = mark
    @boardRate[cell_number] = 0
    update_board_rate(cell_number)
    check_winner
  end
  
  def check_winner
    @winner = find_winner
    game_over unless @winner.nil?
    return MESSAGE_WINER if @winner == USER_MARK
    return MESSAGE_LOSER if @winner == BOT_MARK
    return MESSAGE_DRAW if @step_counter == 9
    ""
  end

  def find_winner
    RELATED_CELLS.each do |cell, cell_pairs| 
      cell_pairs.each do |cell_pair|
        if @board[cell] ==  @board[cell_pair[0]] && @board[cell] ==  @board[cell_pair[1]]
          return @board[cell]
        end
      end
    end 
    nil
  end
  
  def update_board_rate(cell_number)
    RELATED_CELLS[cell_number].each do |cell_pair|
      update_cell_rate(cell_number, cell_pair)
    end
  end
  
  def update_cell_rate(cell_number, cell_pair)
    points = calculate_points(cell_number, cell_pair)
    cell_pair.each do |cell|
      @boardRate[cell] += points if @boardRate[cell] > 0
    end
  end
  
  def calculate_points(cell_number, cell_pair)
    return 20 if @board[cell_number] == BOT_MARK && cell_pair.any? { |c| @board[c] == BOT_MARK }
    return 10 if @board[cell_number] == USER_MARK && cell_pair.any? { |c| @board[c] == USER_MARK }
    1
  end

  def game_over
    @boardRate.map! { 0 }
  end
end
