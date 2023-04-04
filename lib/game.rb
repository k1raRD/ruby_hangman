# frozen_string_literal: true

require 'json'
require 'io/console'
require_relative 'hangman_display'
require_relative 'hangman'

# Class that contains player methods, variables and game flow
class Game
  include HangmanDisplay

  def initialize(computer = Computer.new, round = 0)
    @computer = computer
    @round = round
  end

  def play_game
    intro if @round.zero?
    while @computer.lives.positive? && @computer.word_guessed == false
      load_game if @round.zero?
      @computer.display(@computer.lives)
      @computer.check_guess(player_input)
      @round += 1
    end
    @computer.display(@computer.lives)
    win_loose
  end

  def play_again
    puts 'Play again? y or n?'
    if gets.chomp == 'y'
      reset_game
      play_game
    else
      exit
    end
  end

  def win_loose
    if @computer.lives.zero?
      puts "\nYou loose!\n\n"
      puts "The word was #{@computer.word}!!\n\n"
      play_again
    else
      puts "You win!\n\n"
    end
  end

  def intro
    puts HangmanDisplay::INTRO
    $stdin.getch
  end

  def reset_game
    @computer = Computer.new
    @round = 0
  end

  def player_input
    puts "Please make a guess or type 'save' to save your game"
    input = gets.chomp.downcase
    while !input.match('save') && !input.match?(/^[a-z]$/)
      puts 'Please input One letter a time! Try again...'
      input = gets.chomp.downcase
    end
    want_to_save(input)
    check_if_already_tried(input)
    input
  end

  def check_if_already_tried(input)
    while @computer.word_dashes.to_s.include?(input) ||
          @computer.incorrect_guesses.to_s.include?(input)
      puts "You've already tried this one. Try again..."
      input = gets.chomp.downcase # rubocop:disable Lint/UselessAssignment
    end
  end

  def want_to_save(input)
    return unless input == 'save'

    save_game
    exit
  end

  def save_game
    File.open('save_game.json', 'w') do |file|
      file.puts(computer_to_json)
    end
  end

  def computer_to_json
    JSON.dump({
                word: @computer.word,
                incorrect_guesses: @computer.incorrect_guesses,
                word_dashes: @computer.word_dashes,
                lives: @computer.lives,
                word_guessed: @computer.word_guessed
              })
  end

  def from_json(save_game)
    computer_date = JSON.parse(File.read(save_game))
    @computer = Computer.new(
      computer_date['word'],
      computer_date['incorrect_guesses'],
      computer_date['word_dashes'],
      computer_date['lives'],
      computer_date['word_guessed']
    )
  end

  def load_game
    return unless File.exist?('save_game.json')

    puts 'Would you like to continue where you left off last time? (Enter: "y" or "n")'
    answer = gets.chomp.downcase
    return unless answer == 'y'

    File.open('save_game.json', 'r') do |file|
      from_json(file)
    end
    File.delete('save_game.json')
  end
end

Game.new.play_game
