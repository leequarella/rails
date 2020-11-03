# frozen_string_literal: true

require "cases/helper"
require "models/post"
require "models/author"
require "models/comment"

class HasManyThroughSplitAssociationsTest < ActiveRecord::TestCase
  fixtures :posts, :authors, :comments

  def setup
    @author = authors(:mary)
  end

  def test_counting_on_split_through
    assert_equal @author.comments.count, @author.split_comments.count
    assert_queries(2) { @author.split_comments.count }
    assert_queries(1) { @author.comments.count }
  end

  def test_pluck_on_split
    assert_equal @author.comments.pluck(:id), @author.split_comments.pluck(:id)
    assert_queries(2) { @author.split_comments.pluck(:id) }
    assert_queries(1) { @author.comments.pluck(:id) }
  end
end
