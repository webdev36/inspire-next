class CreateResponseActions < ActiveRecord::Migration
  def change
    create_table :response_actions do |t|
      t.string :response_text

      t.timestamps
    end
  end
end
