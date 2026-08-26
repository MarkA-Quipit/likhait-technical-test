class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy

  before_validation :titleize_name

  validates :name, presence: true, uniqueness: true

  private

  def titleize_name
    self.name = name.to_s.split(" ").map(&:capitalize).join(" ") if name.present?
  end
end
