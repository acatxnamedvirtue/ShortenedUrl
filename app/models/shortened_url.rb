class ShortenedUrl < ActiveRecord::Base
  validates :short_url, { presence: true, uniqueness: true }
  validates :submitter_id, presence: true
  validates :long_url, presence: true
end
