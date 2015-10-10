require 'pry'
require 'redditkit'

def create_bot(username, password)
  RedditKit::Client.new username, password
end

def get_comments_on_post(user, post_title=nil)
  links = user.my_content.select { |p| p.is_a? RedditKit::Link }
  if post_title.nil?
    post = links.first
  else
    post = links.select { |x| x.title == post_title }.first
  end
  RedditKit.comments post
end

def lmgtfy(question)
  URI.encode("http://www.lmgtfy.com/?q=#{question}")
end

# TODO sanitize comment input
# look at body of every comment
# if there is not already a comment by our bot
#   if there is a question mark somewhere in the body
#     google the sentence up to the question mark
#     comment with the lmgtfy link


