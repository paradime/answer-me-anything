require 'pry'
require 'redditkit'
require 'logger'

@logger = Logger.new('reddit.log')
@logger.level = Logger::WARN

@author = 'answer-me-anything'
@opts = {
  username: @author,
  password: 'kenthacks',
  post_title: 'throwaway post do not upboat'
}
@already_commented = []

def create_bot(username, password)
  RedditKit.sign_in username, password
  RedditKit::Client.new username, password
  @logger.info('user signed in')
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
  @logger.info("Making comment for #{question}")
  RedditKit.submit_comment comment, lmgtfy(question)
end

def lmgtfy(question)
  URI.encode("http://www.lmgtfy.com/?q=#{question}")
end

def have_commented?(comment)
  replies_listing = comment.attributes[:replies]
  return false if replies_listing.empty?
  replies_array = replies_listing[:data][:children]
  comment_objects ||= replies_array.map do |comment|
    RedditKit::Comment.new(comment)
  end
  comment_objects.any?{|x| x.author == @author }
end

def populate_already_commented(user)
  comments = get_comments_on_post(user, @opts[:post_title])
  comments.each do |comment|
    if have_commented? comment
      @already_commented << comment.id
    end
  end
end

def process_comments(user, opts = {})
  comments = get_comments_on_post(user, opts[:post_title])
  comments.each do |comment|
    if !@already_commented.include? comment.id
      make_comment comment
      @already_commented << comment.id
    end
  end
end

def search_for_comments
  bot = create_bot(@opts[:username], @opts[:password])
  populate_already_commented bot
  logger.info("Already commented: #{@already_commented}")
  while true
    # SidekiqQueue.perform_async bot, @opts
    process_comments(bot, @opts)
    logger.info('Processing comments')
    logger.info('Sleeping')
    sleep 60
    logger.info('Done sleeping')
  end
end
