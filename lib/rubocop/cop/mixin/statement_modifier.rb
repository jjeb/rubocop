# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for modifier cops.
    module StatementModifier
      include LineLengthHelp

      private

      def single_line_as_modifier?(node)
        return false if non_eligible_node?(node) ||
                        non_eligible_body?(node.body) ||
                        non_eligible_condition?(node.condition)

        modifier_fits_on_single_line?(node)
      end

      def non_eligible_node?(node)
        node.modifier_form? ||
          node.nonempty_line_count > 3 ||
          processed_source.commented?(node.loc.end)
      end

      def non_eligible_body?(body)
        body.nil? ||
          body.empty_source? ||
          body.begin_type? ||
          processed_source.commented?(body.source_range)
      end

      def non_eligible_condition?(condition)
        condition.each_node.any?(&:lvasgn_type?)
      end

      def modifier_fits_on_single_line?(node)
        return true unless max_line_length

        length_in_modifier_form(node) <= max_line_length
      end

      def length_in_modifier_form(node)
        keyword = node.loc.keyword
        prefix = keyword.source_line[0...keyword.column]
        expression = to_modifier_form(node)
        line_length("#{prefix}#{expression}")
      end

      def to_modifier_form(node)
        expression = [node.body.source,
                      node.keyword,
                      node.condition.source].compact.join(' ')
        parenthesized = parenthesize?(node) ? "(#{expression})" : expression
        [parenthesized, first_line_comment(node)].compact.join(' ')
      end

      def first_line_comment(node)
        comment =
          processed_source.find_comment { |c| c.loc.line == node.loc.line }

        comment ? comment.loc.expression.source : nil
      end

      def parenthesize?(node)
        # Parenthesize corrected expression if changing to modifier-if form
        # would change the meaning of the parent expression
        # (due to the low operator precedence of modifier-if)
        parent = node.parent
        return false if parent.nil?
        return true if parent.assignment? || parent.operator_keyword?
        return true if %i[array pair].include?(parent.type)

        node.parent.send_type? && !node.parent.parenthesized?
      end

      def max_line_length
        return unless config.for_cop('Layout/LineLength')['Enabled']

        config.for_cop('Layout/LineLength')['Max']
      end
    end
  end
end
