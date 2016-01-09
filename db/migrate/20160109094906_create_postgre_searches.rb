class CreatePostgreSearches < ActiveRecord::Migration
  def change
    create_table :postgre_searches do |t|
      t.references :searchable, :polymorphic => true, index: true
      t.tsvector :search_data

      t.timestamps null: false
    end

    add_index :postgre_searches, :search_data, using: "gin"
  end
end
