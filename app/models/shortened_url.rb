require 'SecureRandom'

class ShortenedUrl < ActiveRecord::Base
  validates :short_url, { presence: true, uniqueness: true }
  validates :submitter_id, presence: true
  validates :long_url, { presence: true, length: { maximum: 1024 } }
  validate :no_more_than_five_in_last_minute

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

  def self.prune(n)
    all_recent_visits = Visit.where("created_at >= ?", n.minutes.ago)
    recently_visited_url_ids = all_recent_visits.select(:shortened_url_id).
      distinct.map { |visit| visit.shortened_url_id }

    ShortenedUrl.delete(ShortenedUrl.where("id NOT IN (?)", recently_visited_url_ids))

    nil
  end

  def num_clicks
    Visit.where(shortened_url_id: self.id).count
  end

  def num_uniques
    self.visitors.count
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

  private
  def no_more_than_five_in_last_minute
    num_recent_urls_created = ShortenedUrl.
              where(submitter_id: submitter_id).
              where("created_at >= ?", 1.minutes.ago).count
    p num_recent_urls_created
    if num_recent_urls_created >= 5
      errors[:num_recent_urls_created] << "cant be more than five"
    end
  end
end
