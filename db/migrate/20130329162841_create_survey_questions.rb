class CreateSurveyQuestions < ActiveRecord::Migration
  def change
    create_table :survey_questions do |t|
      t.references :survey
      t.string :question_text, null: false, default: ""
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at, default: nil
      t.timestamps
    end
  end
end
