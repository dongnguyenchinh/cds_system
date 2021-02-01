class Approver < ApplicationRecord
  # has_many :project_members
  # has_many :projects, through: :project_members
  belongs_to :user, :class_name => "User"
  belongs_to :approver, :class_name => "User"
  belongs_to :period

  validate :check_3_reviewers

  def check_3_reviewers
    if !is_approver
      reviewer_count = Approver.where(user_id: user_id, is_approver: false, period_id: period_id).length
      if reviewer_count > 3
        errors.add(:approver_id, "An user can only have 3 reviewers")
      end
    end
  end
end
