require File.dirname(__FILE__) + '/../test_helper'

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects,
    :users,
    :roles,
    :members,
    :member_roles,
    :trackers,
    :projects_trackers,
    :enabled_modules,
    :issue_categories,
    :issue_statuses,
    :issues,
    :enumerations,
    :custom_fields,
    :custom_values,
    :custom_fields_trackers

  def setup
    @request.session[:user_id] = 2

    @some_tags = '#1, #2, #3,#4,#5'

    @project_with_tags = Project.find(1)
    @another_project = Project.find(2)

    @issue_with_tags = Issue.find(1)
    @issue_with_tags.tags_to_update = @some_tags
    @issue_with_tags.save!

    @issue_without_tags = Issue.find(2)

    @issues_to_bulk_edit = [@issue_with_tags, @issue_without_tags]
  end

  test "should get global new" do
    get :new
    assert_response :success
  end

  test "should get new" do
    get :new, params: { project_id: @project_with_tags.identifier }
    assert_response :success
  end

  test "index with tags query column" do
    get :index, params: { project_id: @project_with_tags.identifier, set_filter: 1, 'c[]': 'issue_tags' }
    assert_response :success
    assert_select 'td a', text: /#1/
    assert_select 'td a', text: /#2/
  end

  def test_can_index_issues_when_custom_fields_available
    IssueCustomField.create!(
      name:          'cfield',
      default_value: 'ok',
      is_filter:     true,
      field_format:  'string',
      is_for_all:    true
    )

    get :index
    assert_response :success
  end

  def test_bulk_update_with_project_change_should_success
    tag_input = '"1 2 \\\\ 3 cool/tag 777    '

    put :bulk_update, params: {
        ids: @issues_to_bulk_edit.map(&:id),
        issue: { project_id: @another_project.id, tags: tag_input },
        append_tags: 'on'
    }

    assert_response :redirect

    @issue_with_tags.reload
    assert_equal @another_project.id, @issue_with_tags.project_id, 'Project should be changed'

    another_project_context = TaggingPlugin::ContextHelper.context_for(@another_project)
    tags = @issue_with_tags.tags_on(another_project_context)
    assert_equal %w(#1 #2 #3 #4 #5 #777 #cool/tag), tags.map(&:name).sort
  end

  def test_bulk_update_without_project_change_should_success
    tag_input = '"1 2 \\\\ 3 cool/tag 777    '
    put :bulk_update, params: { ids: @issues_to_bulk_edit.map(&:id), issue: { tags: tag_input }, 'append_tags' => 'on' }
    assert_response :redirect

    @issue_with_tags.reload

    project_context = TaggingPlugin::ContextHelper.context_for(@project_with_tags)
    tags = @issue_with_tags.tags_on(project_context)
    assert_equal %w(#1 #2 #3 #4 #5 #777 #cool/tag), tags.map(&:name).sort
  end

  def test_bulk_update_without_tags_field_should_not_drop_tags
    put :bulk_update, params: { :ids => @issues_to_bulk_edit.map(&:id), issue: { status_id: 1 } }
    assert_response :redirect

    @issue_with_tags.reload

    project_context = TaggingPlugin::ContextHelper.context_for(@project_with_tags)
    tags = @issue_with_tags.tags_on(project_context)
    assert_equal %w(#1 #2 #3 #4 #5), tags.map(&:name).sort
  end

  def test_update_without_tags_field_should_not_drop_tags
    put :update, params: { id: @issue_with_tags.id, issue: { status_id: 1 } }
    assert_response :redirect

    @issue_with_tags.reload

    project_context = TaggingPlugin::ContextHelper.context_for(@project_with_tags)
    tags = @issue_with_tags.tags_on(project_context)
    assert_equal %w(#1 #2 #3 #4 #5), tags.map(&:name).sort
  end
end
