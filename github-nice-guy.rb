require 'github_api'
require 'dotenv'
require 'mail'
Dotenv.load

class GithubNiceGuy
  def self.run
    Mail.defaults do
    delivery_method :smtp,
        address: ENV['SMTP_ADDRESS'],
        port: 587,
        domain: ENV['SMTP_DOMAIN'],
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: 'plain'
    end

    github = Github.new basic_auth: ENV["GITHUB_BASIC_AUTH"]
    issues = github.search.issues q: "type:pr is:open user:#{ENV['SEARCH_USER']}"

    unless issues.empty?
      mail_body = "Hello,<br><br> Here are some pull requests for #{ENV['SEARCH_USER']} that you \
      might want to give a look to:<br><br>"
      issues.items.map do |item|
          mail_body += "<a href='#{item.pull_request.url}'>#{item.title}</a> by #{item.user.login}<br>"
      end
      mail_body += "<br>The Github Nice Guy."

      Mail.new do
          from ENV['SMTP_USERNAME']
          to ENV['RECIPIENTS'].split(',')
          subject "Open #{ENV['SEARCH_USER']} pull requests"

          html_part do
          content_type 'text/html; charset=UTF-8'
          body mail_body
          end
      end.deliver
    end
  end
end
