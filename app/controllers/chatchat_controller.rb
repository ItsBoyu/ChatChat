require 'line/bot'
class ChatchatController < ApplicationController
  skip_forgery_protection

  def webhook
    # 核心程式
    # reply_message = reply(received_message)

    # render plain: params

    # 查天氣
    reply_image = get_weather(received_text)

    # 有查到的話，後面的事情就不做了
    unless reply_image.nil?
      # 傳送訊息到 line
      response = reply_image_to_line(reply_image)

      # 回應200
      head :ok

      return
    end

    # 記錄頻道
    # Channel.create_or_find_by(channel_id: channel_id)
    Channel.find_or_create_by(channel_id: channel_id)

    # 設定回覆文字
    # 學說話
    reply_text = learn(channel_id, received_text)

    # 關鍵字回覆
    reply_text = keyword_reply(channel_id, received_text) if reply_text.nil?

    # 推齊功能
    reply_text = echo2(channel_id, received_text) if reply_text.nil?

    # 記錄對話
    save_to_received(channel_id, received_text)
    save_to_reply(channel_id, reply_text)

    # 傳送訊息到 line
    response = reply_to_line(reply_text)

    # 回應200
    head :ok
  end

  def get_weather(received_text)
    return nil unless received_text.include? '天氣'
    upload_to_imgur(get_weather_from_cwb)
  end

  def get_weather_from_cwb
    uri = URI('https://www.cwb.gov.tw/Data/js/obs_img/Observe_radar.js')
    response = Net::HTTP.get(uri)
    start_index = response.index('":\'') + 3
    end_index = response.index('\',') - 1
    'https://www.cwb.gov.tw/Data/radar/' + response[start_index..end_index]
  end

  def upload_to_imgur(img_url)
    url = URI('https://api.imgur.com/3/image')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['authorization'] = ENV["imgur_client_id"]

    request.set_form_data({'image' => img_url})
    response = http.request(request)
    json = JSON.parse(response.read_body)
    begin
      json['data']['link'].gsub('http:', 'https:')
    rescue
      nil
    end
  end

  def reply_image_to_line(reply_image)
    return nil if reply_image.nil?

    # 取得 reply token
    reply_token = params['events'][0]['replyToken']

    # 設定回覆訊息
    message = {
      type: 'image',
      originalContentUrl: reply_image,
      previewImageUrl: reply_image
    }

    # 傳送訊息
    line.reply_message(reply_token, message)
  end

  def learn(channel_id, received_text)
    # 如果開頭不是 chat學說話;
    return nil unless received_text[0..7] == "chat學說話;"
    
    received_text = received_text[8..-1]
    semicolon_index = received_text.index(';')

    # 找不到分號就結束
    return nil if semicolon_index.nil?

    keyword = received_text[0..semicolon_index-1]
    message = received_text[semicolon_index+1..-1]

    KeywordMapping.create(channel_id: channel_id, keyword: keyword, message: message)
    '我會了！'
  end

  # 取得對方說的話
  def received_text
    # params["events"][0]["message"] 不一定有值
    # params["events"][0]["message"]["text"]

    message = params["events"][0]["message"]
    message['text'] unless message.nil?

  end

  # 關鍵字回覆
  def keyword_reply(channel_id, received_text)
    # 學習記錄表
    # keyword_mapping = {
    #   '中島美嘉' => '神曲支援：https://www.youtube.com/watch?v=QL3T2Nzcqcs',
    #   '女王蜂' => '神曲支援：https://www.youtube.com/watch?v=gn-YwSmEzNc'
    # }

    # 查表
    # keyword_mapping[received_text]

    # 新增訊息
    message = KeywordMapping.where(channel_id: channel_id, keyword: received_text).last&.message
    return message unless message.nil?

    KeywordMapping.where(keyword: received_text).last&.message
  end

  # 頻道ID
  def channel_id
    source = params['events'][0]['source']
    source['groupId'] || source['roomId'] || source['userId']
  end

  # 儲存對話
  def save_to_received(channel_id, received_text)
    return if received_text.nil?
    Received.create(channel_id: channel_id, text: received_text)
  end

  # 儲存回應
  def save_to_reply(channel_id, reply_text)
    return if reply_text.nil?
    Reply.create(channel_id: channel_id, text: reply_text)
  end

  def echo2(channel_id, received_text)
    # 如果在 channel_id 沒人講過 received_text 就不回應
    recent_received_texts = Received.where(channel_id: channel_id).last(5)&.pluck(:text)
    return nil unless received_text.in? recent_received_texts

    # 如果在 channel_id 上一句回應是 received_text 就不回應
    last_reply_text = Reply.where(channel_id: channel_id).last&.text
    return nil if last_reply_text == received_text

    received_text
  end

  # 傳送訊息到 line
  def reply_to_line(reply_text)
    return nil if reply_text.nil?

    # 取得 reply token
    reply_token = params["events"][0]["replyToken"]

    # 設定回覆訊息
    message = {
      type: "text",
      text: reply_text
    }

    # 傳送訊息
    line.reply_message(reply_token, message)
  end


  # Line Bot API 物件初始化
  def line
    # return @line if not @line.nil?
    @line ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["channel_secret"]
      config.channel_token = ENV["channel_token"]
    }
  end

  def eat
    render plain: "這是 Controller"
  end

  def request_headers
    render plain: request.headers.to_h.reject{ |key, value|
      key.include? "." }.map{ |key, value|
      "#{key} : #{value}"
      # "#{key} : #{value.class}"
      # key + " : " + value.class.to_s
    }.sort.join("\n")
  end

  def request_body
    render plain: request.body
  end

  def show_response_body
    puts "設定前的response.body:#{request.body}"
    render plain: "哈哈哈"
    puts "設定前的response.body:#{request.body}"
  end

  def sent_request
    uri = URI('https://localhost:3000/chatchat/eat')
    http = Net::HTTP.new(uri.host, uri.port)
    http_request = Net::HTTP::Get.new(uri)
    http_response = http.request(http_request)

    render plain: JSON.pretty_generate({
      request_class: request.class,
      response_class: response.class,
      http_request_class: http_request.class,
      http_response_class: http_response.class
    })
  end

  def translate_to_korean(message)
    "#{message}油"
  end

end
