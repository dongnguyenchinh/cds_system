require "test_helper"

class CompetencyTest < ActiveSupport::TestCase
  # fixtures :competencies
  test "product attributes must not be empty" do
    competency = Competency.new
    assert product.invalid?
    assert product.errors[:title].any?
    assert product.errors[:description].any?
    assert product.errors[:price].any?
    assert product.errors[:image_url].any?
    end
end
