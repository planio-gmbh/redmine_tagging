module RedmineTagging::Patches::ProjectPatch
  def self.apply
    Project.send :prepend, self unless Project < self
  end

  def tags
    ActsAsTaggableOn::Tag.
        joins(:taggings).
        joins(<<-SQL
          inner join #{Issue.table_name} issues on
            issues.project_id = #{ActiveRecord::Base::sanitize(id)} and
            issues.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id
        SQL
        ).order(:name).uniq
  end
end

