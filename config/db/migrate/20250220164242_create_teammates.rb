# frozen_string_literal: true

ROM::SQL.migration do
  # Add your migration here.
  #
  # See https://guides.hanamirb.org/v2.2/database/migrations/ for details.
  change do
    create_table :teammates do
      primary_key :id
      column :name, :text, null: false
    end
  end
end
