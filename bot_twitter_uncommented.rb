require 'twitter'

def query_twitter
  require_relative 'auth'
  Twitter::REST::Client.new do |config|
    config.consumer_key        = MY_CONSUMER_KEY
    config.consumer_secret     = MY_CONSUMER_SECRET
    config.access_token        = MY_ACCESS_TOKEN
    config.access_token_secret = MY_ACCESS_TOKEN_SECRET
  end
end

def search_emails
  client = query_twitter
  tweets = client.search("\@ -RT email", result_type: "recent").take(200)

  # transform_array_with_each(tweets)
  # transform_array_with_map(tweets)
  transform_array_with_each_with_object(tweets)
end

def transform_array_with_each(array)
  results = []
  array.each do |tweet|
    email = "#{tweet.text}".match(/\w+\.?\+?\w+?@\w+\-?\w+\.\w+/)
    results << email.to_s unless email == nil
  end
  results
end


def transform_array_with_map(array)
  array.map do |tweet|
    result = "#{tweet.text}".match(/\w+\.?\+?\w+?@\w+\-?\w+\.\w+/)
    result.to_s unless result == nil
  end.compact.uniq
end


def transform_array_with_each_with_object(array)
  array.each_with_object([]) do |tweet, results|
    email = "#{tweet.text}".match(/\w+\.?\+?\w+?@\w+\-?\w+\.\w+/)
    results << email.to_s if email
  end.uniq
end

def delete_doubles(param)
  emails = param
  saved_emails = File.readlines("tweets.txt").map { |email| email.chomp }
  emails = emails - saved_emails
end

def save_emails
  counter = 0
  emails = delete_doubles(search_emails)
  emails.each do |email|
    counter += 1
    File.open("tweets.txt", 'a'){|file| file.write(email + "\n")}
  end
  puts "#{counter} files added to the file"
end

save_emails
