require 'pry'
require 'redditkit'

def create_bot(username, password)
  RedditKit.sign_in username, password
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

def make_comment(comment)
  question = comment.body
  RedditKit.submit_comment comment, lmgtfy(question)
end

def lmgtfy(question)
  URI.encode("http://www.lmgtfy.com/?q=#{question}")
end

def process_comments(opts = {})
  bot = create_bot(opts[:username], opts[:password])
  comments = get_comments_on_post(bot, opts[:post_title])
  not_replied_to_yet = []
  comments.first.attributes[:replies][:data][:children].each do |x|
    not_replied_to_yet << x if x[:data][:author] != opts[:username]
  end
  binding.pry
  not_replied_to_yet.each do |comment|
    make_comment comment
  end
end

def have_commented(comment)
  replies_listing = comment.attributes[:replies]
  return [] if replies_listing.empty?
  replies_array = replies_listing[:data][:children]
  comment_objects ||= replies_array.map do |comment|
    RedditKit::Comment.new(comment)
  end
  comment_objects.any?{|x| x.author == 'answer-me-anything'}
end


# TODO sanitize comment input
# look at body of every comment
# if there is not already a comment by our bot
#   if there is a question mark somewhere in the body
#     google the sentence up to the question mark
#     comment with the lmgtfy link


