class Visit < ActiveRecord::Base
  validates :shortened_url_id, presence: true
  validates :user_id, presence: true

  def self.record_visit!(user, short_url)
    Visit.create!(user_id: user.id, shortened_url_id: short_url.id)
  end

  belongs_to :visitor_id,
    class_name: "User",
    foreign_key: :user_id,
    primary_key: :id

  belongs_to :short_url,
    class_name: "ShortenedUrl",
    foreign_key: :shortened_url_id,
    primary_key: :id
end
