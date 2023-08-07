class CreateAnonymizedAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :anonymized, :boolean, default: false, null: false
  end
end
