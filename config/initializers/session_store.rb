if Rails.env.production?
  Rails.application.config.session_store :cookie_store, key: '_my_session', expire_after: 1.weeks, domain: ENV['HOST']
else
  Rails.application.config.session_store :cookie_store, key: '_my_session', domain: ENV['HOST']
end
