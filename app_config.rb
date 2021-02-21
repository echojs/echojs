# General
SiteName = "Echo JS"
SiteUrl = ENV["SITE_URL"] || "http://www.echojs.com"
SiteDescription = "JavaScript News"

SiteNews = "Site News : Follow Echo JS on Twitter, our official account is : <a href=\"https://twitter.com/echojs\">@echojs</a>"

# Redis config
RedisURL = ENV['REDIS_URL'] || "redis://127.0.0.1:6379"

# Security
PBKDF2Iterations = 1000 # Set this to 5000 to improve security. But it is slow.
UseOpenSSL = false
PasswordMinLength = 8

# Comments
CommentMaxLength = 4096
CommentEditTime = 3600*2
CommentReplyShift = 60
UserCommentsPerPage = 10
SubthreadsInRepliesPage = 10

# Karma
UserInitialKarma = 1
KarmaIncrementInterval = 3600
KarmaIncrementAmount = 1
NewsDownvoteMinKarma = 30
NewsDownvoteKarmaCost = 6
DeletedNewsKarmaRefund = 12
NewsUpvoteMinKarma = 1
NewsUpvoteKarmaCost = 1
NewsUpvoteKarmaTransfered = 1
KarmaIncrementComment = 1

# UI Elements
KeyboardNavigation = 1

# User
DeletedUser = {"username" => "deleted_user", "email" => "", "id" => -1}
UserCreationDelay = 3600*24
PasswordResetDelay = 3600*24
UsernameRegexp = /^[a-zA-Z][a-zA-Z0-9_\-]+$/

# News and ranking
NewsAgePadding = 3600*8
TopNewsPerPage = 30
LatestNewsPerPage = 30
NewsEditTime = 60*15
NewsScoreLogStart = 10
NewsScoreLogBooster = 2
RankAgingFactor = 1.1
NewsSubmissionBreak = 3600*24
PreventRepostTime = 3600*24*30
SavedNewsPerPage = 10
TopNewsAgeLimit = 3600*24*30

# Footer links
FooterTwitterLink = "https://twitter.com/echojs"
FooterGoogleGroupLink = false

# API
APIMaxNewsCount = 32

# Email service. Set MailRelay to false to disable this functionality
# (this will prevent users from recovery accounts if the password gets lost).
MailRelay = ENV["MAIL_RELAY"] || "localhost"
MailFrom = ENV["MAIL_FROM"] || "robot@echojs.com"
