require File.dirname(__FILE__) + '/../test_helper'

class IssuesApiTest < Redmine::ApiTest::Base
  fixtures :projects,
    :users, :email_addresses,
    :roles,
    :members,
    :member_roles,
    :trackers,
    :projects_trackers,
    :enabled_modules,
    :issue_categories,
    :issue_statuses,
    :issues,
    :enumerations

  setup do
    @some_tags = '#tagthat, #tagthis'
    @issue_with_tags = Issue.find(1)
    @issue_with_tags.tags_to_update = @some_tags
    @issue_with_tags.save!
    @project_with_tags = @issue_with_tags.project
    @dlopper = User.find_by_login('dlopper')
  end

  test "issue index with tags" do
    assert Setting.rest_api_enabled?
    assert @dlopper.allowed_to?(:view_issues, @project_with_tags)
    get "/projects/#{@project_with_tags.identifier}/issues.xml", headers: credentials('dlopper', 'foo')
    assert_response :success
    assert_select 'issues>issue>tags>tag[id=tagthis]'
  end

  test "global issues index with tags" do
    get "/issues.xml", headers: credentials('dlopper', 'foo')
    assert_response :success
    assert_select 'issues>issue>tags>tag[id=tagthis]'
  end

  test "issue show with tags" do
    get "/issues/#{@issue_with_tags.id}.xml", headers: credentials('dlopper', 'foo')
    assert_response :success
    assert_select 'issue>tags>tag[id=tagthis]'
  end
end
