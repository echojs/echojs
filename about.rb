get '/about' do
    H.set_title "About - #{SiteName}"
    H.page {
        H.div(:id => "about") {
            H.h2 {"#{SiteName}"}+
            H.p {"Echo JS is a community-driven news site entirely focused on JavaScript development, HTML5, and front-end news."}+

            H.h3 { "Staff" }+
            H.p { "Admin: " + H.a(:href => "http://www.allanic.org") {"Fabien Allanic"} }+
            H.p { "Admin: " + H.a(:href => "https://www.tracker1.info") {"Michael J. Ryan"} }+

            H.h3 { "Former Staff" }+
            H.p { "Founder: " + H.a(:href => "https://www.cambus.net") {"Frederic Cambus"} }+
            H.p { "Admin: " + H.a(:href => "http://www.echojs.com/user/sbruchmann") {"Steffen Bruchmann"} }+

            H.h3 { "Twitter" }+
            H.p { "Follow Echo JS on Twitter, our official account is: " + H.a(:href => "https://twitter.com/echojs", :rel => "nofollow") {"@echojs"} }+

            H.h3 {"News"}+
            H.ul {
                H.li { "[2015-02-16] Echo JS has partnered with O'Reilly's " + H.a(:href => "http://www.echojs.com/news/13509") {"Fluent Conference"} + " 2015" }+
                H.li { "[2014-01-08] Echo JS has partnered with O'Reilly's " + H.a(:href => "http://www.echojs.com/news/7985") {"Fluent Conference"} + ". March 11-13, 2014 in San Francisco" }+
                H.li { "[2013-06-18] We are happy to sponsor the 2013 edition of the " + H.a(:href => "http://www.echojs.com/news/4689") {"DemoJS"} + " Demoparty!" }+
                H.li { "[2013-02-25] Echo JS has partnered with O'Reilly's " + H.a(:href => "http://www.echojs.com/news/3000") {"Fluent Conference"} + ": JavaScript & Beyond. May 28-30, 2013 in San Francisco" }+
                H.li { "[2013-02-08] Echo JS is happy to sponsor the Spring 2013 edition of the " + H.a(:href => "http://www.echojs.com/news/2776") {"JS1K competition"} + "!" }
            }+

            H.h3 {"Giveaways"}+
            H.ul {
                H.li { "[2015-02-22] Echo JS is running a " + H.a(:href => "http://www.echojs.com/news/13607") {"conference pass giveaway"} + " for Oreilly\'s Fluent Conference 2015" }+
                H.li { "[2014-01-08] Echo JS is running a " + H.a(:href => "http://www.echojs.com/news/7994") {"conference pass giveaway"} + " for Oreilly\'s Fluent Conference 2014" }+
                H.li { "[2013-05-22] Win a " + H.a(:href => "http://www.echojs.com/news/4214") {"WebStorm license"} + " (the smartest JavaScript IDE by JetBrains) with Echo JS" }+
                H.li { "[2013-03-25] Echo JS is running a " + H.a(:href => "http://www.echojs.com/news/3358") {"conference pass giveaway"} + " for Oreilly\'s Fluent Conference \"JavaScript and Beyond\"!" }
            }+

            H.h3 {"Third-party applications"}+
            H.ul {
                H.li { "Desktop: " + H.a(:href => "https://github.com/sbruchmann/echojs-desktop-reader", :rel => "nofollow") {"EchoJS Desktop Reader "} + " by Steffen Bruchmann (works on Linux, Mac OSX and Windows)" }+
                H.li { "iPhone: " + H.a(:href => "#", :rel => "nofollow") {"sonarJS"} + " by Damien Klinnert (Source code: " + H.a(:href => "https://github.com/damienklinnert/sonarjs", :rel => "nofollow") {"GitHub"} + ")" }+
                H.li { "WP8: " + H.a(:href => "http://www.windowsphone.com/en-gb/store/app/echoesjs/e85de08b-11cf-4eb8-a1c6-f3ee1eff9561", :rel => "nofollow") {"EchoesJS"} + " by Christopher Shepherd (Source code: " + H.a(:href => "https://github.com/Sheepsteak/EchoesJS", :rel => "nofollow") {"GitHub"} + ")" }
            }+

            H.h3 {"General rules for posting"}+
            H.ul {
                H.li {"Edit titles: only article title, no blog name, no period at the end"}+
                H.li {"Edit URLs: no tracking codes"}+
                H.li {"Respect the case: JavaScript, not javascript or javaScript or Javascript"}+
                H.li {"Tag articles older than one year. Example: Welcome to Echo JS! (2011)"}+
                H.li {"No link to summaries, only link to original content"}+
                H.li {"No link to newsletters, see previous rule"}+
                H.li {"No URL shortened links, only real links to pages"}+
                H.li {"No commercial content or libraries (even with free demo)"}+
                H.li {"JavaScript related content only"}+
                H.li {"English content only"}
            }
        }
    }
end
