require File.dirname(__FILE__) + '/../test_helper'

class TagSearchTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :projects_trackers, :enabled_modules

  setup do
    @user = User.find_by_admin(true)
    @project = Project.find(1)

    @issue = @project.issues.first
    @issue.tag_list_ctx = 'tag1 tag2'
    @issue.save

    wiki = Wiki.create!(project: @project, start_page: 'test')
    @page = WikiPage.create!(title: 'test', content: WikiContent.new(text: 'content'), tags: 'tag2 tag3', wiki: wiki)
    @page.save!
  end

  test 'should search issues by tag' do
    f = Redmine::Search::Fetcher.new('tag1', @user, ['issues', 'wiki_pages'], [@project], titles_only: false)
    assert_equal 1, f.result_count
    results = f.results(0, 10)
    assert_equal @issue, results.first
  end

  test 'should search wiki pages by tag' do
    f = Redmine::Search::Fetcher.new('tag3', @user, ['issues', 'wiki_pages'], [@project], titles_only: false)
    assert_equal 1, f.result_count
    results = f.results(0, 10)
    assert_equal @page, results.first
  end

  test 'should find issues and wiki pages by tag' do
    f = Redmine::Search::Fetcher.new('tag2', @user, ['issues', 'wiki_pages'], [@project], titles_only: false)
    assert_equal 2, f.result_count
    results = f.results(0, 10)
    assert results.include?(@issue)
    assert results.include?(@page)
  end
end
