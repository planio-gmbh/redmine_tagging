module RedmineTagging
  def self.dynamic_font_size?
    Setting.plugin_redmine_tagging["dynamic_font_size"] == "1"
  end
end
