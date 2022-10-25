module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    class StyleStack
      def initialize
        @stack = []
      end

      def clear_finished
        @stack.delete_if { !!_1[:finish] }
      end

      def each(&block)
        @stack.reverse_each.group_by { _1[:tagname] }.each do |_, descriptors|
          overlapping_ranges = find_overlapping_styles(descriptors)
          widest_descriptor = overlapping_ranges.max_by { (_1[:start].._1[:finish]).size }

          applicable_styles = descriptors - overlapping_ranges + [widest_descriptor].compact
          applicable_styles.each(&block)
        end
      end

      def track_start(tagname, current_character_offset)
        style = DraftjsHtml::HtmlDefaults::HTML_STYLE_TAGS_TO_STYLE[tagname]
        @stack.unshift({ tagname: tagname, style: style, start: current_character_offset })
      end

      def track_end(tagname, current_character_offset)
        descriptor_index = @stack.find_index { _1[:tagname] == tagname && !_1[:finish] }
        descriptor = @stack[descriptor_index]
        descriptor[:finish] = current_character_offset
      end

      private

      def find_overlapping_styles(descriptors)
        descriptors.select do |candidate_a|
          candidate_range = candidate_a[:start]..candidate_a[:finish]
          (descriptors - [candidate_a]).any? do |other|
            other_range = other[:start]..other[:finish]
            range_overlaps?(candidate_range, other_range)
          end
        end
      end

      def range_overlaps?(candidate_range, other_range)
        other_range.begin == candidate_range.begin || candidate_range.cover?(other_range.begin) || other_range.cover?(candidate_range.begin)
      end
    end
  end
end
