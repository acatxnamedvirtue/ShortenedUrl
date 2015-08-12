require 'SecureRandom'

class ShortenedUrl < ActiveRecord::Base
  validates :short_url, { presence: true, uniqueness: true }
  validates :submitter_id, presence: true
  validates :long_url, presence: true

  def self.random_code
    code = SecureRandom.urlsafe_base64

    until !ShortenedUrl.exists?(short_url: code)
      code = SecureRandom.urlsafe_base64
    end

    code
  end

  def self.create_for_user_and_long_url!(user, long_url)
    ShortenedUrl.create!(
      short_url: self.random_code, long_url: long_url, submitter_id: user.id
    )
  end

  def num_clicks
    Visit.where(shortened_url_id: self.id).count
  end

  def num_uniques
    self.visitors.count
      # where(shortened_url_id: self.id).
      # select(:user_id).distinct.count
  end

  def num_recent_uniques
    Visit.
      where(shortened_url_id: self.id).
      where("created_at >= ?", 10.minutes.ago).
      select(:user_id).distinct.count
  end

  belongs_to :submitter,
    class_name: "User",
    foreign_key: :submitter_id,
    primary_key: :id

  has_many :visits,
    class_name: "Visit",
    foreign_key: :shortened_url_id,
    primary_key: :id

  has_many :visitors,
    -> { distinct },
    through: :visits,
    source: :visitor_id
end
