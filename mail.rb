require 'net/http'
require 'net/smtp'

# Check if an email is valid, in a not very future-proof way.
def is_valid_email?(mail)
    # Characters allowed on name: 0-9a-Z-._ on host: 0-9a-Z-. on between: @
    return false if mail !~ /^[0-9a-zA-Z\.\-\_\+]+\@[0-9a-zA-Z\.\-]+$/

    # Must start or end with alpha or num
    return false if mail =~ /^[^0-9a-zA-Z]|[^0-9a-zA-Z]$/

    # Name must end with alpha or num
    return false if mail !~ /([0-9a-zA-Z]{1})\@./

    # Host must start with alpha or num
    return false if mail !~ /.\@([0-9a-zA-Z]{1})/

    # Host must end with '.' plus 2 or 3 or 4 alpha for TopLevelDomain
    # (MUST be modified in future!)
    return false if mail !~ /\.([a-zA-Z]{2,4})$/

    return true
end

# Send an email using the Mailgun HTTP API or SMTP relay.
#
# When MailgunApiKey and MailgunDomain are set, uses the Mailgun HTTP API.
# Otherwise falls back to SMTP using the specified relay host.
#
# 'relay' is an IP address or hostname of an SMTP server (used as fallback).
# 'from' can be a string or a two elements array [name,address].
# 'to' is a comma separated list of recipients.
# 'subject' and 'body' are just strings.
#
# If opt[:html] is true a set of headers to send HTML emails are emitted.
#
# The function does not try to send emails to destination addresses that
# appear to be invalid. If at least one error occurs sending the email, then
# false is returned and the operation aborted, otherwise true is returned.
def mail(relay,from,to,subject,body,opt={})
    if MailgunApiKey && MailgunDomain
        return mailgun_send(from,to,subject,body,opt)
    else
        return smtp_send(relay,from,to,subject,body,opt)
    end
end

def mailgun_send(from,to,subject,body,opt={})
    uri = URI("https://api.mailgun.net/v3/#{MailgunDomain}/messages")
    req = Net::HTTP::Post.new(uri)
    req.basic_auth('api', MailgunApiKey)

    from_header = from.is_a?(Array) ? "#{from[0]} <#{from[1]}>" : from

    params = {
        'from' => from_header,
        'to' => to,
        'subject' => subject,
        'text' => body
    }

    if opt[:html]
        params['html'] = body
    end

    req.set_form_data(params)

    begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            response = http.request(req)
            return response.is_a?(Net::HTTPSuccess)
        end
    rescue Exception => e
        return false
    end
end

def smtp_send(relay,from,to,subject,body,opt={})
    header=''
    if opt[:html]
        header << "MIME-Version: 1.0\r\n"
        header << "Content-type: text/html;"
        header << "charset=utf-8\r\n"
    end

    if from.is_a?(Array)
        header << "From: "+from[0]+" <"+from[1]+">"
        from=from[1]
    else
        header << "From: "+from
    end

    message = <<END_OF_MESSAGE
#{header}
To: #{to}
Subject: #{subject}

#{body}
END_OF_MESSAGE

    status = true
    Net::SMTP.start(relay) {|smtp|
        to.split(",").each {|dest|
            dest = dest.strip
            if is_valid_email? dest
                smtp.send_message(message,from,dest)
            else
                status = false
            end
        }
    }
    return status
rescue Exception => e
    return false
end
