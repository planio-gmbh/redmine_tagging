require File.dirname(__FILE__) + '/../test_helper'

class TagcloudTest < ViewComponent::TestCase

  fixtures :projects, :issues, :trackers, :projects_trackers, :issue_statuses

  setup do
    @project = Project.find(1)
    @issue = @project.issues.first
  end

  test "should render empty tagcloud" do
    render_inline RedmineTagging::Tagcloud.new(@project)
    assert_selector 'h3', text: 'Tags'
    assert_selector 'a', count: 0
  end

  test "should render tagcloud" do
    @issue.tags_to_update = '#some, #tags'
    @issue.save!
    render_inline RedmineTagging::Tagcloud.new(@project)
    assert_selector 'h3', text: 'Tags'
    assert_selector 'a', count: 2
  end
end
