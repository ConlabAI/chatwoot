module Anonymization
  require 'digest/md5'

  def self.anonymize_email(email, user_id)
    rng = Random.new(Digest::MD5.hexdigest(user_id.to_s).to_i(16))
    prefix, domain = email.split('@')
    random_prefix = Array.new(prefix.length) { ('a'..'z').to_a[rng.rand(26)] }.join
    "#{random_prefix}@#{domain}"
  end

  def self.anonymize_phone(phone, user_id)
    rng = Random.new(Digest::MD5.hexdigest(user_id.to_s).to_i(16))
    Array.new(phone.length) { rng.rand(10).to_s }.join
  end

  def self.anonymize_name(name, user_id)
    Faker::Config.locale = 'ru'
    Faker::Config.random = Random.new(Digest::MD5.hexdigest(user_id.to_s).to_i(16))

    first_name = Faker::Name.male_first_name
    last_name = Faker::Name.male_last_name

    "#{first_name} #{last_name}"
  end

  def self.anonymize_avatar_url(id)
    "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(id.to_s)}?d=identicon"
  end
end
