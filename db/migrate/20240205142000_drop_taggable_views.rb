class DropTaggableViews < ActiveRecord::Migration[5.2]
  def down
  end

  def up
    execute 'DROP VIEW IF EXISTS issue_tags'
    execute 'DROP VIEW IF EXISTS wiki_page_tags'
  end

  def run_in_request?; true end
end

