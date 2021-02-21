FROM ruby:2.7.2

RUN gem install rails bundler unicorn

WORKDIR /app
COPY . .

RUN bundle install

ENV PORT=80 APP_ENV=production
EXPOSE 80

CMD ["ruby", "app.rb"]
