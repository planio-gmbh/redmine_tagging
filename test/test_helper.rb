# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

class ActiveSupport::TestCase
  def setup_wiki_page_with_tags(test_tags)
    public_project = Project.find(1)

    Wiki.create!(project_id: public_project.id, start_page: 'test_page')
    public_project.reload

    public_project.wiki.pages << WikiPage.new(title: 'some_wiki_page')
    page = public_project.wiki.pages.first
    page.tags = test_tags
    page.content = WikiContent.new(text: 'content')
    page.save!
    page
  end
end
