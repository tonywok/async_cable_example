class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_from(game_channel_key)
    stream_from(player_channel_key)

    game_instance.join(player_channel_key)
  end

  def start
    unless game_instance.status.running? || game_instance.status.waiting?
      messages = game_instance.start
      messages.each do |message|
        broadcast(message.channel_key, message.as_json)
      end
    end
  end

  def load
    messages = game_instance.load(player_channel_key)
    messages.each do |message|
      broadcast(message.channel_key, message.as_json)
    end
  end

  def decide(option:)
    messages = game_instance.decide(option)
    messages.each do |message|
      broadcast(message.channel_key, message.as_json)
    end
  end

  private

  FakeGameRecord = Struct.new(:id, keyword_init: true)

  def game_record
    @game_record ||= FakeGameRecord.new(id: 2)
  end

  def game_instance
    @game_instance ||= AsyncCable.instance(FabTcg::Gameplay::Game.new(game_record.id))
  end

  def game_channel_key
    "game:#{game_record.id}"
  end

  def player_channel_key
    "#{game_channel_key}::player:#{current_user.id}"
  end
end