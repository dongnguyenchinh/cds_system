class Form < ApplicationRecord
  belongs_to :periods, optional: true
  belongs_to :user
  has_many :form_slots
  has_many :form_histories
end
