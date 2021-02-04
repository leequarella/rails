# frozen_string_literal: true

require "cases/helper"

require "models/post"
require "models/author"
require "models/comment"
require "models/rating"
require "models/member"
require "models/member_type"

require "models/pirate"
require "models/treasure"

require "models/hotel"
require "models/department"

class HasManyThroughSplitAssociationsTest < ActiveRecord::TestCase
  fixtures :posts, :authors, :comments, :pirates

  def setup
    @author = authors(:mary)
    @post = @author.posts.create(title: "title", body: "body")
    @member_type = MemberType.create(name: "club")
    @member = Member.create(member_type: @member_type)
    @comment = @post.comments.create(body: "text", resource: @member)
    @post2 = @author.posts.create(title: "title", body: "body")
    @member2 = Member.create(member_type: @member_type)
    @comment2 = @post2.comments.create(body: "text", resource: @member2)
    @rating1 = @comment.ratings.create(value: 8)
    @rating2 = @comment.ratings.create(value: 9)
  end

  def test_counting_on_split_through
    assert_equal @author.comments.count, @author.split_comments.count
    assert_queries(2) { @author.split_comments.count }
    assert_queries(1) { @author.comments.count }
  end

  def test_counting_on_split_through_using_custom_foreign_key
    assert_equal @author.comments_2.count, @author.split_comments_2.count
    assert_queries(2) { @author.split_comments_2.count }
    assert_queries(1) { @author.comments_2.count }
  end

  def test_pluck_on_split_through
    assert_equal @author.comments.pluck(:id), @author.split_comments.pluck(:id)
    assert_queries(2) { @author.split_comments.pluck(:id) }
    assert_queries(1) { @author.comments.pluck(:id) }
  end

  def test_pluck_on_split_through_using_custom_foreign_key
    assert_equal @author.comments_2.pluck(:id), @author.split_comments_2.pluck(:id)
    assert_queries(2) { @author.split_comments_2.pluck(:id) }
    assert_queries(1) { @author.comments_2.pluck(:id) }
  end

  def test_fetching_on_split_through
    assert_equal @author.comments.first.id, @author.split_comments.first.id
    assert_queries(2) { @author.split_comments.first.id }
    assert_queries(1) { @author.comments.first.id }
  end

  def test_fetching_on_split_through_using_custom_foreign_key
    assert_equal @author.comments_2.first.id, @author.split_comments_2.first.id
    assert_queries(2) { @author.split_comments_2.first.id }
    assert_queries(1) { @author.comments_2.first.id }
  end

  def test_to_a_on_split_through
    assert_equal @author.comments.to_a, @author.split_comments.to_a
    @author.reload
    assert_queries(2) { @author.split_comments.to_a }
    assert_queries(1) { @author.comments.to_a }
  end

  def test_appending_on_split_through
    assert_difference(->() { @author.split_comments.reload.size }) do
      @post.comments.create(body: "text")
    end
    assert_queries(2) { @author.split_comments.reload.size }
    assert_queries(1) { @author.comments.reload.size }
  end

  def test_appending_on_split_through_using_custom_foreign_key
    assert_difference(->() { @author.split_comments_2.reload.size }) do
      @post.comments_2.create(body: "text")
    end
    assert_queries(2) { @author.split_comments_2.reload.size }
    assert_queries(1) { @author.comments_2.reload.size }
  end

  def test_empty_on_split_through
    empty_author = authors(:bob)
    assert_equal [], assert_queries(0) { empty_author.comments.all }
    assert_equal [], assert_queries(1) { empty_author.split_comments.all }
  end

  def test_empty_on_split_through_using_custom_foreign_key
    empty_author = authors(:bob)
    assert_equal [], assert_queries(0) { empty_author.comments_2.all }
    assert_equal [], assert_queries(1) { empty_author.split_comments_2.all }
  end

  def test_pluck_on_split_through_a_through
    rating_ids = Rating.where(comment: @comment).pluck(:id)
    assert_equal rating_ids, assert_queries(1) { @author.ratings.pluck(:id) }
    assert_equal rating_ids, assert_queries(3) { @author.split_ratings.pluck(:id) }
  end

  def test_count_on_split_through_a_through
    ratings_count = Rating.where(comment: @comment).count
    assert_equal ratings_count, assert_queries(1) { @author.ratings.count }
    assert_equal ratings_count, assert_queries(3) { @author.split_ratings.count }
  end

  def test_count_on_split_using_relation_with_scope
    assert_equal 2, assert_queries(1) { @author.good_ratings.count }
    assert_equal 2, assert_queries(3) { @author.split_good_ratings.count }
  end

  def test_to_a_on_split_with_multiple_scopes
    assert_equal [@rating1, @rating2], assert_queries(1) { @author.good_ratings.to_a }
    assert_equal [@rating1, @rating2], assert_queries(3) { @author.split_good_ratings.to_a }
  end

  def test_preloading_has_many_through_split
    assert_queries(3) { Author.all.preload(:good_ratings).map(&:good_ratings) }
    assert_queries(4) { Author.all.preload(:split_good_ratings).map(&:good_ratings) }
  end

  def test_polymophic_split_through_counting
    assert_equal 2, assert_queries(1) { @author.ordered_members.count }
    assert_equal 2, assert_queries(3) { @author.split_ordered_members.count }
  end

  def test_polymophic_split_through_ordering
    assert_equal [@member2, @member], assert_queries(1) { @author.ordered_members.to_a }
    assert_equal [@member2, @member], assert_queries(3) { @author.split_ordered_members.to_a }
  end

  def test_polymorphic_split_through_reordering
    assert_equal [@member, @member2], assert_queries(1) { @author.ordered_members.reorder(id: :asc).to_a }
    assert_equal [@member, @member2], assert_queries(3) { @author.split_ordered_members.reorder(id: :asc).to_a }
  end

  def test_polymorphic_split_through_ordered_scopes
    assert_equal [@member2, @member], assert_queries(1) { @author.ordered_members.unnamed.to_a }
    assert_equal [@member2, @member], assert_queries(3) { @author.split_ordered_members.unnamed.to_a }
  end

  def test_polymorphic_split_through_ordered_chained_scopes
    member3 = Member.create(member_type: @member_type)
    member4 = Member.create(member_type: @member_type, name: "named")
    @post2.comments.create(body: "text", resource: member3)
    @post2.comments.create(body: "text", resource: member4)

    assert_equal [member3, @member2, @member], assert_queries(1) { @author.ordered_members.unnamed.with_member_type_id(@member_type.id).to_a }
    assert_equal [member3, @member2, @member], assert_queries(3) { @author.split_ordered_members.unnamed.with_member_type_id(@member_type.id).to_a }
  end

  def test_polymorphic_split_through_ordered_scope_limits
    assert_equal [@member2], assert_queries(1) { @author.ordered_members.unnamed.limit(1).to_a }
    assert_equal [@member2], assert_queries(3) { @author.split_ordered_members.unnamed.limit(1).to_a }
  end

  def test_polymorphic_split_through_ordered_scope_first
    assert_equal @member2, assert_queries(1) { @author.ordered_members.unnamed.first }
    assert_equal @member2, assert_queries(3) { @author.split_ordered_members.unnamed.first }
  end
end
