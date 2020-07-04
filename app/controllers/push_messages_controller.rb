require 'line/bot'
class PushMessagesController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    text = params[:text]
    Channel.all.each do |channel|
      push_to_line(channel.channel_id, text)
    end
    redirect_to '/push_messages/new'
  end

  private
  # 傳訊息到 line
  def push_to_line(channel_id, text)
    return nil if channel_id.nil? || text.nil?

    # 設定回覆訊息
    message = {
      type: 'text',
      text: text
    }

    # 傳送訊息
    line.push_message(channel_id, message)
  end

  # Line Bot API 物件初始化
  def line
    # return @line if not @line.nil?
    @line ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["channel_secret"]
      config.channel_token = ENV["channel_token"]
    }
  end

end
