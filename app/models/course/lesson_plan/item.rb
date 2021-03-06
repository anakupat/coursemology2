# frozen_string_literal: true
class Course::LessonPlan::Item < ActiveRecord::Base
  actable
  has_many_attachments

  after_initialize :set_default_values, if: :new_record?

  # @!method self.ordered_by_date
  #   Orders the lesson plan items by the starting date.
  scope :ordered_by_date, (lambda do
    order { start_at }
  end)

  belongs_to :course, inverse_of: :lesson_plan_items

  # Gives the maximum number of EXP Points that an EXP-awarding item
  # is allocated to give, which is the sum of base and bonus EXPs.
  #
  # @return [Integer] Maximum EXP awardable.
  def total_exp
    base_exp + time_bonus_exp + extra_bonus_exp
  end

  private

  # Sets default EXP values
  def set_default_values
    self.base_exp ||= 0
    self.time_bonus_exp ||= 0
    self.extra_bonus_exp ||= 0
  end
end
