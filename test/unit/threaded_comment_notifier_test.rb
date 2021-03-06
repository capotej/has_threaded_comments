require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class ThreadedCommentNotifierTest < ActionMailer::TestCase

  def setup
    @sample_book = {
      :title => "This is a test title",
      :content => "Wow! This item has some content!"
    }
    @sample_comment = {
      :name => 'Test Commenter', 
      :body => 'This the medium size comment body...', 
      :email => "test@example.com", 
      :threaded_comment_polymorphic_id => 1, 
      :threaded_comment_polymorphic_type => 'Book'
    }
    @test_book = Book.create!(@sample_book)
    @test_comment = @test_book.comments.create!(@sample_comment.merge({:threaded_comment_polymorphic_id => nil, :threaded_comment_polymorphic_type => nil}))
  end
  
  test "should send new comment notification" do
    assert_difference("ActionMailer::Base.deliveries.length", 1) do
      @email = ThreadedCommentNotifier.deliver_new_comment_notification( @test_comment )
    end
    assert_equal [THREADED_COMMENTS_CONFIG["admin_email"]], @email.to
    assert_equal [THREADED_COMMENTS_CONFIG["system_send_email_address"]], @email.from
    assert @email.subject.index( "New" ), "Email subject did not include 'New':\n#{@email.subject}"
    assert @email.body.index( @test_comment.body ), "Email did not include comment body:\n#{@email.body}"
    assert @email.body.index( @test_comment.name ), "Email did not include comment name:\n#{@email.body}"
    assert @email.body.index( @test_comment.email ), "Email did not include comment email address:\n#{@email.body}"
    assert @email.body.index( THREADED_COMMENTS_CONFIG["site_domain"] + "/books/#{@test_comment.owner_item.id}#threaded_comment_" + @test_comment.id.to_s ), "Email did not include link to comment:\n#{@email.body}"
  end
  
  test "should send user comment reply notification" do
    assert_difference("ActionMailer::Base.deliveries.length", 1) do
      @email = ThreadedCommentNotifier.deliver_comment_reply_notification( 'test@test.com', @test_comment )
    end
    assert_equal [THREADED_COMMENTS_CONFIG["system_send_email_address"]], @email.from
    assert @email.body.index( @test_comment.body ), "Email did not include comment body:\n#{@email.body}"
    assert @email.body.index( @test_comment.name ), "Email did not include comment name:\n#{@email.body}"
    assert_nil @email.body.index( @test_comment.email ), "Email should not include comment email address:\n#{@email.body}"
    assert @email.body.index( THREADED_COMMENTS_CONFIG["site_domain"] + "/books/#{@test_comment.owner_item.id}\n" ), "Email did not include link to comment parent item:\n#{@email.body}"
    assert @email.body.index( THREADED_COMMENTS_CONFIG["site_domain"] + "/books/#{@test_comment.owner_item.id}#threaded_comment_" + @test_comment.id.to_s ), "Email did not include link to comment:\n#{@email.body}"
  end
  
  test "should send failed comment notification" do
    assert_difference("ActionMailer::Base.deliveries.length", 1) do
      @email = ThreadedCommentNotifier.deliver_failed_comment_creation_notification( @test_comment )
    end
    assert_equal [THREADED_COMMENTS_CONFIG["admin_email"]], @email.to
    assert_equal [THREADED_COMMENTS_CONFIG["system_send_email_address"]], @email.from
    assert @email.subject.index( "Failed" ), "Email subject did not include 'Failed'"
    assert @email.body.index( @test_comment.body ), "Email did not include comment body"
    assert @email.body.index( @test_comment.name ), "Email did not include comment name"
    assert @email.body.index( @test_comment.email ), "Email did not include comment email address"
  end
  
end
