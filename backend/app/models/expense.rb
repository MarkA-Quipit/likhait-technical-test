class Expense < ApplicationRecord
  belongs_to :category
  validate :date_not_in_future

  private

  def date_not_in_future
    return if date.blank?

    errors.add(:date, "can't be in the future") if date.future?
  end
end
