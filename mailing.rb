require 'rubygems'
require 'yaml'
require 'gmail'
require 'sqlite3'

@config = YAML.load_file("config.yml")
@mail_account = @config['mailing']
@db = SQLite3::Database.new( @config["db_path"] )
@gmail = Gmail.new(@mail_account['login'], @mail_account['password'])

def content_from_part(part)
  content = ""
  content += part.body.decoded if part.content_type =~ /^text\/plain.*format=flowed$/
  part.parts.each do |inside_part|
    content += content_from_part inside_part
  end
  return content
end

def content_from_multipart_mail(email)
  content = ""
  email.parts.each do |part|
    content += content_from_part part
  end
  return content
end

def insert_email_as_post(email_index)
  if email = @gmail.inbox.emails(:unread, :to => "tetalab@lists.tetalab.org")[email_index]
    content = content_from_multipart_mail(email) if email.multipart?
    title = email.subject.gsub("[Tetalab] ", "")
    @db.execute("INSERT INTO blog_posts (title, body, draft, published_at, created_at) VALUES (?, ?, 'true', ?, ?)", [title, content, Time.now.to_s, Time.now.to_s])
    puts "'#{title}' inserted in db"
  else
    puts "no mail found with this index"
  end
end

def select_email_to_insert
  index = 0
  puts "[0] - mark all as read"
  @gmail.inbox.emails(:unread, :to => "tetalab@lists.tetalab.org").each do |email|
    puts "[#{index}] - #{email.subject}"
    index += 1
    email.mark :unread
  end
  puts "---"
  puts "please make a choice with: ruby mailing.rb x"
end

def mark_all_read
  @gmail.inbox.emails(:unread, :to => "tetalab@lists.tetalab.org")..each{|email| email.mark :read}
  puts "All mails marked as read"
end

# Console interface
if ARGV[0] && index = ARGV[0].to_i
  if index == 0
    mark_all_read
  else
    insert_email_as_post index
  end
else
  select_email_to_insert
end
