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
    @user = ENV['SEARCH_USER']
    @issues = github.search.issues q: "type:pr is:open user:#{@user}"

    unless @issues.empty?
      template = ERB.new(File.read("mail_template.erb"))
      mail_body = template.result(binding)

      Mail.new do
        from ENV['SMTP_USERNAME']
        to ENV['RECIPIENTS'].split(',')
        subject "[Github Nice Guy] There are #{@issues.total_count} open pull requests for #{@user}"

        html_part do
          content_type 'text/html; charset=UTF-8'
          body mail_body
        end
      end.deliver
    end
  end
end

GithubNiceGuy.run if ENV['RUN']
