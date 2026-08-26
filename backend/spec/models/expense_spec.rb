require 'rails_helper'

RSpec.describe Expense, type: :model do
  let!(:category) { Category.create!(name: "Food") }

  it "is invalid with a future date" do
    expense = Expense.new(description: "Future", amount: 10.00, category: category, date: Date.tomorrow)
    expect(expense).not_to be_valid
    expect(expense.errors[:date]).to include("can't be in the future")
  end

  it "is valid with today's date" do
    expense = Expense.new(description: "Today", amount: 10.00, category: category, date: Date.current)
    expect(expense).to be_valid
  end

  it "is valid with a past date" do
    expense = Expense.new(description: "Past", amount: 10.00, category: category, date: Date.current - 5.days)
    expect(expense).to be_valid
  end
end
