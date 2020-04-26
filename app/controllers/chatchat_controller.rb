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
    render plain: params
  end
end
