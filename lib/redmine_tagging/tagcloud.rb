module RedmineTagging
  class Tagcloud < ViewComponent::Base
    delegate :l, to: :helpers

    erb_template <<-ERB
      <h3><%= l :field_tags %></h3>
      <div id="tagcloud">
        <%= safe_join tagcloud, ' ' %>
      </div>
    ERB

    def initialize(project, link_to: :issues)
      @project = project
      @link_to = link_to
    end

    private

    def self.tag_filter_link_options(tag, status: 'o')
      {
        'set_filter'     => 1,
        'f'              => ['tags', 'status_id'],
        'op[tags]'       => '=',
        'op[status_id]'  => status,
        'v[tags][]'      => tag_without_sharp(tag),
        'v[status_id][]' => 1
      }
    end

    def self.tag_cloud_in_project(project)
      tags = {}
      context = TaggingPlugin::ContextHelper.context_for(project)
      project.issues.tag_counts_on(context).each do |tag|
        tags[tag.name] = tag.count
      end
      project.wiki.pages.tag_counts_on(context).each do |tag|
        tags[tag.name] = tags[tag.name].to_i + tag.count
      end if project.wiki

      tags.reject!{|key, value| value == 0 }

      if tags.size > 0
        min_max = tags.values.minmax
        distance = min_max[1] - min_max[0]

        dynamic_fonts_enabled = RedmineTagging.dynamic_font_size?

        tags.keys.sort_by { |t| t.downcase }.map do |tag|
          if dynamic_fonts_enabled && (distance != 0)
            count = tags[tag]
            factor = (count - min_max[0]).to_f / distance
          else
            factor = 0.0
          end
          yield tag, factor
        end
      else
        []
      end
    end

    def tagcloud
      self.class.tag_cloud_in_project(@project) do |tag, factor|
        if @link_to == :issues
          link_to(
            tag,
            project_issues_path(@project, self.class.tag_filter_link_options(tag)),
            tag_html_options(factor)
          )
        else
          link_to(
            tag,
            { controller: "search", action: "index", id: @project, q: "\"#{self.class.tag_without_sharp(tag)}\"", wiki_pages: true },
            tag_html_options(factor)
          )
        end
      end
    end

    def tag_html_options(factor)
      {}.tap do |options|
        if RedmineTagging.dynamic_font_size?
          options[:style] = "font-size: #{10 * factor + 9}pt"
        end
      end
    end

    def self.tag_without_sharp(tag)
      tag.to_s.sub(/^\s*#/, '')
    end
  end
end
