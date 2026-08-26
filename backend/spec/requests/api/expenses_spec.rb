require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
    it "returns all expenses with category information" do
      Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.today)
      Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.today)

      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "returns expenses in descending order by date" do
      older_expense = Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: 5.days.ago.to_date)
      newer_expense = Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.today)

      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(newer_expense.id)
      expect(json.last["id"]).to eq(older_expense.id)
    end

    it "breaks ties on the same date using created_at descending" do
      same_date = Date.today
      earlier_created = Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: same_date, created_at: 1.hour.ago)
      later_created = Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: same_date, created_at: Time.current)

      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(later_created.id)
      expect(json.last["id"]).to eq(earlier_created.id)
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.today
          }
        }
      end

      it "creates a new expense" do
        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq(150.5)
      end
    end

    context "with invalid parameters" do
      it "with negative amounts" do
        invalid_params = {
          expense: {
            description: "Invalid expense",
            amount: -100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "with empty descriptions" do
        invalid_params = {
          expense: {
            description: "",
            amount: 100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    it "with a future date" do
      future_params = {
        expense: {
          description: "Future expense",
          amount: 100.00,
          category_id: food_category.id,
          date: Date.tomorrow
        }
      }

      expect {
        post "/api/expenses", params: future_params, as: :json
      }.not_to change(Expense, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Date can't be in the future")
    end

    it "with today's date" do
      today_params = {
        expense: {
          description: "Today expense",
          amount: 100.00,
          category_id: food_category.id,
          date: Date.current
        }
      }

      expect {
        post "/api/expenses", params: today_params, as: :json
      }.to change(Expense, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PUT /api/expenses/:id" do
    let!(:expense) do
      Expense.create!(
        description: "Lunch",
        amount: 100.00,
        category: food_category,
        date: Date.today
      )
    end

    context "with a valid category_id" do
      it "updates the expense's category" do
        put "/api/expenses/#{expense.id}",
            params: { expense: { category_id: transport_category.id } },
            as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["category"]).to eq("Transport")

        expense.reload
        expect(expense.category_id).to eq(transport_category.id)
      end
    end

    context "with a partial update omitting category_id" do
      it "leaves the existing category unchanged" do
        put "/api/expenses/#{expense.id}",
            params: { expense: { description: "Lunch updated" } },
            as: :json

        expect(response).to have_http_status(:success)
        expense.reload
        expect(expense.category_id).to eq(food_category.id)
        expect(expense.description).to eq("Lunch updated")
      end
    end
  end
end
