class CreateTests < ActiveRecord::Migration[7.1]
  def change
    create_table :tests do |t|
      t.string :title, null: false
      t.references :teacher, null: false, foreign_key: true
      t.string :locale, null: false

      t.timestamps
    end
  end
end
