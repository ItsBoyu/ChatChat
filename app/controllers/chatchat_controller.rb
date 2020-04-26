require 'line/bot'
class ChatchatController < ApplicationController
  skip_forgery_protection
  def eat
    render plain: "這是 Controller"
  end

  def request_headers
    render plain: request.headers.to_h.reject{ |key, value| key.include? "." }.map{ |key, value|
      "#{key} : #{value}"
      # "#{key} : #{value.class}"
      # key + " : " + value.class.to_s
    }.sort.join("\n")
  end

  def webhook
    # Line Bot API 物件初始化
    client = Line::Bot::Client.new { |config|
      config.channel_secret = '92d001c6a3ea46401d239d1c82f1c5f6'
      config.channel_token = 'jEKnpF4gBjr11XJyVDr0+SNgCz52mC2mZKIIfedzlbfn609io61vQPCZThkEMjRK8ZmUavoi32u2wjNGNTgrgf0QsdZec1QJOZEZ63QRaWAx5xnRmg6VRRegiX1oHi1wBdJhjoWkP/xx/qCid8yOLAdB04t89/1O/w1cDnyilFU='
  }

    # 取得 reply token
    reply_token = params['event'][0]['replyToken']

    # 設定回覆訊息
    message = {
      type: 'text',
      text: '我知道了～'
    }

    # 傳送訊息
    response = client.reply_message(reply_token, message)

    # 回應200
    head :ok
  end
end
