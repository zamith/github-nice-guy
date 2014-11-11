require 'github_api'
require 'dotenv'
require 'mail'
require 'erb'
Dotenv.load

class GithubNiceGuy
  def self.run
    Mail.defaults do
      delivery_method :smtp,
        address: ENV['SMTP_ADDRESS'] || "smtp.gmail.com",
        port: ENV['SMTP_PORT'] || 587,
        domain: ENV['SMTP_DOMAIN'] || "gmail.com",
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: ENV['SMTP_AUTH'] || 'plain'
    end

    github = Github.new basic_auth: ENV["GITHUB_BASIC_AUTH"]
    issues = github.search.issues q: "type:pr is:open user:#{ENV['SEARCH_USER']}"

    unless issues.empty?
      template = ERB.new(File.read("mail_template.erb"))
      mail_body = template.result(binding)

      Mail.new do
        from ENV['SMTP_USERNAME']
        to ENV['RECIPIENTS'].split(',')
        subject "[Github Nice Guy] There are #{issues.total_count} open pull requests for #{ENV['SEARCH_USER']}"

        html_part do
          content_type 'text/html; charset=UTF-8'
          body mail_body
        end
      end.deliver
    end
  end
end

GithubNiceGuy.run if ENV['RUN']
