require 'rubygems'
require 'yaml'
require 'gmail'
require 'sqlite3'
require 'redcarpet'
require 'htmlentities'
require 'iconv'

@config = YAML.load_file("config.yml")
@mail_account = @config['mailing']
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

def retrieve_db
  puts "retrieving db from server..."
  `scp -P 22101 webadmin@tetalab.org:/var/www/refinery/shared/db/production.sqlite3 #{@config["db_path"]}`
  puts "db retrieved"
end

def send_db
  puts "sending db to server..."
  `scp -P 22101 #{@config["db_path"]} webadmin@tetalab.org:/var/www/refinery/shared/db/production.sqlite3`
  puts "db sent"
end

def insert_db_post(title, content)
  post_time = (Time.now - 3600).to_s
  @db = SQLite3::Database.new( @config["db_path"] )
  query = "INSERT INTO blog_posts (title, body, draft, published_at, created_at, updated_at, user_id) VALUES (?, ?, ?, ?, ?, ?, ?)"
  @db.execute(query, [title, content, 't', post_time, post_time, post_time, 1])
  send_db
end

def insert_email_as_post(email_index)
  if email = @gmail.inbox.emails(:unread, :to => "tetalab@lists.tetalab.org")[email_index]

    coder = HTMLEntities.new
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)

    title = email.subject.gsub("[Tetalab] ", "")

    content = content_from_multipart_mail(email) if email.multipart?
    content = Iconv.iconv('utf-8', 'iso8859-1', content).first
    content = markdown.render(content)
    #coder.encode(content, :decimal))

    insert_db_post(title, content)

    puts "'#{title}' inserted in db"
  else
    puts "no mail found with this index"
  end
end

def select_email_to_insert
  index = 0
  puts "[0] - mark all as read"
  @gmail.inbox.emails(:unread, :to => "tetalab@lists.tetalab.org").each do |email|
    index += 1
    puts "[#{index}] - #{email.subject}"
    email.mark :unread
  end
  puts "---"
  puts "please make a choice with: ruby mailing.rb x"
end

def mark_all_read
  @gmail.inbox.emails(:unread, :to => "tetalab@lists.tetalab.org").each{|email| email.mark :read}
  puts "All mails marked as read"
end

# Console interface
if ARGV[0] && index = ARGV[0].to_i
  case index
    when -1 then retrieve_db
    when 0 then mark_all_read
    else insert_email_as_post(index - 1)
  end
else
  select_email_to_insert
end
