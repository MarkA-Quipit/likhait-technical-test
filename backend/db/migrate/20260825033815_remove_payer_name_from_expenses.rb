class RemovePayerNameFromExpenses < ActiveRecord::Migration[7.2]
  def change
    remove_column :expenses, :payer_name, :string
  end
end
