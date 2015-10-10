require 'pry'
require 'redditkit'
require 'logger'
require 'bitly'

Bitly.use_api_version_3

@logger = Logger.new('reddit.log')

@author = 'answer-me-anything'
@opts = {
  username: @author,
  password: 'kenthacks',
#  post_title: 'throwaway post do not upboat'
#  post_title: 'We wrote a bot in 2 hours at Kent Hack Enough that will answer any question. AMA'
  post_title: 'We wrote a bot for Kent Hack Enough that will answer all questions. AUA'
}

@client_id = 'answermeanything'
@client_secret = 'R_ae88288f0f9b45c0bce0893852f1f798'

@already_commented = []

@query_required = ['http://www.lmgtfy.com/?q=', 'https://lmddgtfy.net/?q=', 'http://letmebingthatforyou.com/?q=', 'http://www.wolframalpha.com/input/?i=', 'http://www.letmewikipediathatforyou.com/?q=']
@no_query_required = ['http://42.com/', 'http://techsmartly.net/freePS3.php']

def create_bot(username, password)
  RedditKit.sign_in username, password
  @logger.info('user signed in')
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
  comment_text = generate_bitly get_random_url(comment.body)
  @logger.info("Making comment for #{comment_text}")
  RedditKit.submit_comment comment, comment_text
end

def get_random_url(question)
  url = (@query_required + @no_query_required).sample
  if @query_required.include? url
    url = add_query_to_url url, question
  end
  url
end

def add_query_to_url(url, question)
  URI.encode("#{url}#{question}")
end

def generate_bitly(link)
  bitly = Bitly.new @client_id, @client_secret
  bitly.shorten(link).short_url
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
  @logger.info("Already commented: #{@already_commented}")
  while true
    process_comments(bot, @opts)
    @logger.info('Processing comments')
    @logger.info('Sleeping')
    sleep 60
    @logger.info('Done sleeping')
  end
end

search_for_comments
